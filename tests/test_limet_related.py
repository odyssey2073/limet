import json
import os
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))
import limet_related as lr  # noqa: E402


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.t = self.tmp.name
        self.cer = os.path.join(self.t, "cerebro")
        os.makedirs(self.cer)
        self.reg = os.path.join(self.cer, "projects.json")
        self.a = self.mk("a_dir", "alpha")
        self.b = self.mk("b_dir", "beta")
        self.write_reg({
            "alpha": {"docs": ["d1"], "root": self.a},
            "beta": {"docs": ["d2"], "root": self.b + os.sep},
            "other": {"docs": ["x"], "root": "C:\\x", "extra_key": 1},
        })
        p1 = mock.patch.object(lr, "qdrant_up", return_value=True)
        p2 = mock.patch.object(lr, "qdrant_has_collection", return_value=True)
        p1.start()
        p2.start()
        self.addCleanup(p1.stop)
        self.addCleanup(p2.stop)

    def mk(self, parent, name):
        p = os.path.join(self.t, parent, name)
        os.makedirs(os.path.join(p, ".github"))
        with open(os.path.join(p, "AGENTS.md"), "w", encoding="utf-8", newline="") as f:
            f.write("# Mine\r\ncustom\r\n")
        return p

    def write_reg(self, d):
        with open(self.reg, "w", encoding="utf-8") as f:
            json.dump(d, f)

    def read_reg(self):
        with open(self.reg, encoding="utf-8") as f:
            return json.load(f)

    def read(self, p, name="AGENTS.md"):
        with open(os.path.join(p, name), "rb") as f:
            return f.read().decode("utf-8")


def quiet(*_):
    pass


class PureTests(unittest.TestCase):
    def test_slug(self):
        self.assertEqual(lr.slug_of("C:\\P\\CSI-COSMO\\"), "csi_cosmo")
        self.assertEqual(lr.slug_of("/home/u/My App/"), "my_app")

    def test_merge_idempotent_and_keeps_existing(self):
        m = lr.merge_collections(["CRB_ws"], ["CRB_b", "CRB_a", "CRB_b"], "CRB_a")
        self.assertEqual(m, ["CRB_ws", "CRB_b"])
        self.assertEqual(lr.merge_collections(m, ["CRB_b"], "CRB_a"), m)

    def test_block_upsert_strip_roundtrip_eol(self):
        for eol in ("\n", "\r\n"):
            text = "# T" + eol + "x" + eol
            fn = lambda e: lr.START + e + "b" + e + lr.END  # noqa: E731
            new = lr.upsert_block(text, fn)
            self.assertIn(eol + lr.START, new)
            self.assertEqual(lr.upsert_block(new, fn), new)
            self.assertEqual(lr.strip_block(new).strip(), text.strip())

    def test_unbalanced_markers_raise(self):
        with self.assertRaises(lr.RelatedError):
            lr.upsert_block("a " + lr.START, lambda e: lr.START + lr.END)
        with self.assertRaises(lr.RelatedError):
            lr.strip_block(lr.END + "x" + lr.START)

    def test_strip_without_block_returns_none(self):
        self.assertIsNone(lr.strip_block("nothing"))


class LinkTests(Base):
    def test_link_symmetric_and_untouched_others(self):
        lr.link(self.cer, [self.a, self.b], log=quiet)
        r = self.read_reg()
        self.assertEqual(r["alpha"]["collections"], ["CRB_beta"])
        self.assertEqual(r["beta"]["collections"], ["CRB_alpha"])
        self.assertEqual(r["other"], {"docs": ["x"], "root": "C:\\x", "extra_key": 1})
        self.assertEqual(r["alpha"]["docs"], ["d1"])
        self.assertTrue(os.path.isfile(self.reg + ".bak"))
        txt = self.read(self.a)
        self.assertIn("CRB_beta", txt)
        self.assertTrue(txt.startswith("# Mine\r\ncustom"))
        self.assertIn("\r\n" + lr.START, txt)

    def test_link_idempotent(self):
        lr.link(self.cer, [self.a, self.b], log=quiet)
        before = self.read_reg(), self.read(self.a)
        lr.link(self.cer, [self.a, self.b], log=quiet)
        self.assertEqual((self.read_reg(), self.read(self.a)), before)

    def test_preserves_workspace_collection(self):
        r = self.read_reg()
        r["alpha"]["collections"] = ["CRB_ws"]
        self.write_reg(r)
        lr.link(self.cer, [self.a, self.b], log=quiet)
        self.assertEqual(self.read_reg()["alpha"]["collections"], ["CRB_ws", "CRB_beta"])

    def test_workspace_collection_not_listed_as_related(self):
        ws = os.path.dirname(self.a)
        r = self.read_reg()
        r["a_dir"] = {"docs": [], "root": ws}
        r["alpha"]["collections"] = ["CRB_a_dir"]
        self.write_reg(r)
        self.assertEqual(lr.related_of(r, "alpha"), [])

    def test_requires_two(self):
        with self.assertRaises(lr.RelatedError):
            lr.link(self.cer, [self.a], log=quiet)

    def test_not_registered_blocks_without_writing(self):
        c = self.mk("c_dir", "gamma")
        raw = open(self.reg, "rb").read()
        with self.assertRaises(lr.RelatedError):
            lr.link(self.cer, [self.a, c], log=quiet)
        self.assertEqual(open(self.reg, "rb").read(), raw)
        self.assertNotIn(lr.START, self.read(self.a))

    def test_slug_collision(self):
        a2 = self.mk("z_dir", "alpha")
        with self.assertRaises(lr.RelatedError) as cm:
            lr.link(self.cer, [self.a, a2], log=quiet)
        self.assertIn("duplicato", str(cm.exception))

    def test_root_mismatch(self):
        a2 = self.mk("z_dir", "alpha")
        with self.assertRaises(lr.RelatedError) as cm:
            lr.link(self.cer, [a2, self.b], log=quiet)
        self.assertIn("altra cartella", str(cm.exception))

    def test_invalid_json_no_write(self):
        with open(self.reg, "w") as f:
            f.write("{bad")
        with self.assertRaises(lr.RelatedError):
            lr.link(self.cer, [self.a, self.b], log=quiet)
        self.assertEqual(open(self.reg).read(), "{bad")

    def test_collection_missing_blocks(self):
        with mock.patch.object(lr, "qdrant_has_collection", return_value=False):
            with self.assertRaises(lr.RelatedError):
                lr.link(self.cer, [self.a, self.b], log=quiet)

    def test_qdrant_down_blocks(self):
        with mock.patch.object(lr, "qdrant_up", return_value=False):
            with self.assertRaises(lr.RelatedError):
                lr.link(self.cer, [self.a, self.b], log=quiet)

    def test_bad_markers_abort_everything(self):
        with open(os.path.join(self.b, "AGENTS.md"), "w", encoding="utf-8") as f:
            f.write(lr.START + "\nno end")
        raw = open(self.reg, "rb").read()
        with self.assertRaises(lr.RelatedError):
            lr.link(self.cer, [self.a, self.b], log=quiet)
        self.assertEqual(open(self.reg, "rb").read(), raw)
        self.assertNotIn(lr.START, self.read(self.a))

    def test_rollback_on_file_write_failure(self):
        raw = open(self.reg, "rb").read()
        real = lr._write_atomic

        def flaky(path, data):
            if path.endswith("AGENTS.md") and os.path.dirname(path) == self.b:
                raise OSError("boom")
            return real(path, data)

        with mock.patch.object(lr, "_write_atomic", side_effect=flaky):
            with self.assertRaises(lr.RelatedError):
                lr.link(self.cer, [self.a, self.b], log=quiet)
        self.assertEqual(open(self.reg, "rb").read(), raw)
        self.assertNotIn(lr.START, self.read(self.a))

    def test_lock_timeout(self):
        open(self.reg + ".lock", "w").close()
        with mock.patch.object(lr, "LOCK_TIMEOUT", 0.3):
            with self.assertRaises(lr.RelatedError):
                lr.link(self.cer, [self.a, self.b], log=quiet)

    def test_three_projects_mesh(self):
        c = self.mk("c_dir", "gamma")
        r = self.read_reg()
        r["gamma"] = {"docs": [], "root": c}
        self.write_reg(r)
        lr.link(self.cer, [self.a, self.b, c], log=quiet)
        self.assertEqual(self.read_reg()["gamma"]["collections"], ["CRB_alpha", "CRB_beta"])


class UnlinkTests(Base):
    def setUp(self):
        super().setUp()
        lr.link(self.cer, [self.a, self.b], log=quiet)

    def test_unlink_pair(self):
        lr.unlink(self.cer, [self.a, self.b], log=quiet)
        r = self.read_reg()
        self.assertNotIn("collections", r["alpha"])
        self.assertNotIn("collections", r["beta"])
        self.assertNotIn(lr.START, self.read(self.a))
        self.assertEqual(self.read(self.a), "# Mine\r\ncustom\r\n")

    def test_unlink_wrong_root_same_slug_refused(self):
        a2 = self.mk("z_dir", "alpha")
        raw = open(self.reg, "rb").read()
        with self.assertRaises(lr.RelatedError):
            lr.unlink(self.cer, [a2], log=quiet)
        self.assertEqual(open(self.reg, "rb").read(), raw)

    def test_unlink_unregistered_refused(self):
        with self.assertRaises(lr.RelatedError):
            lr.unlink(self.cer, [os.path.join(self.t, "nope", "ghost")], log=quiet)

    def test_unlink_missing_folder_but_registered_root_ok(self):
        import shutil
        shutil.rmtree(self.b)
        lr.unlink(self.cer, [self.b], log=quiet)
        self.assertNotIn("collections", self.read_reg()["alpha"])

    def test_detach_single(self):
        r = self.read_reg()
        r["alpha"]["collections"] = ["CRB_ws"] + r["alpha"]["collections"]
        self.write_reg(r)
        lr.unlink(self.cer, [self.b], log=quiet)
        r = self.read_reg()
        self.assertEqual(r["alpha"]["collections"], ["CRB_ws"])
        self.assertNotIn("collections", r["beta"])


class InitFixTests(Base):
    def test_add_extra_merge(self):
        lr.add_extra(self.cer, "alpha", "CRB_ws")
        lr.add_extra(self.cer, "alpha", "CRB_ws")
        lr.link(self.cer, [self.a, self.b], log=quiet)
        lr.add_extra(self.cer, "alpha", "CRB_ws")
        self.assertEqual(self.read_reg()["alpha"]["collections"], ["CRB_ws", "CRB_beta"])


if __name__ == "__main__":
    unittest.main()
