(function(){
'use strict';
const $=(s,r=document)=>r.querySelector(s), $$=(s,r=document)=>[...r.querySelectorAll(s)];
const store={get(k,d){try{const v=localStorage.getItem('limet-guida:'+k);return v===null?d:JSON.parse(v)}catch(e){return d}},
  set(k,v){try{localStorage.setItem('limet-guida:'+k,JSON.stringify(v))}catch(e){}}};

/* ---------- navigation ---------- */
const pages=$$('section.page');
const nav=$('#nav');
let lastGrp='';
pages.forEach(p=>{
  if(p.dataset.grp!==lastGrp){lastGrp=p.dataset.grp;const g=document.createElement('div');g.className='grp';g.textContent=lastGrp;nav.appendChild(g)}
  const a=document.createElement('a');a.href='#'+p.id;a.dataset.id=p.id;
  a.innerHTML='<span>'+p.dataset.ico+'</span><span>'+p.dataset.title+'</span><span class="ck">✔</span>';
  nav.appendChild(a);
});
let seen=new Set(store.get('seen',[]));
function show(id){
  if(!pages.some(p=>p.id===id))id=pages[0].id;
  pages.forEach(p=>p.classList.toggle('on',p.id===id));
  $$('a',nav).forEach(a=>{a.classList.toggle('active',a.dataset.id===id);a.classList.toggle('seen',seen.has(a.dataset.id))});
  seen.add(id);store.set('seen',[...seen]);
  $$('a',nav).forEach(a=>a.classList.toggle('seen',seen.has(a.dataset.id)));
  $('#progress').style.width=(seen.size/pages.length*100)+'%';
  window.scrollTo(0,0);$('#side').classList.remove('open');
  document.title='LIMET — '+$('#'+id).dataset.title;
}
window.addEventListener('hashchange',()=>show(location.hash.slice(1)));
// pager
pages.forEach((p,i)=>{
  const d=document.createElement('div');d.className='pager';
  const prev=pages[i-1],next=pages[i+1];
  d.innerHTML=(prev?'<a class="btn" href="#'+prev.id+'">← '+prev.dataset.title+'</a>':'<span></span>')+
              (next?'<a class="btn pri" href="#'+next.id+'">'+next.dataset.title+' →</a>':'<span></span>');
  p.appendChild(d);
});
$('#burger').onclick=()=>$('#side').classList.toggle('open');
$('#q').addEventListener('input',e=>{
  const t=e.target.value.toLowerCase().trim();
  $$('a',nav).forEach(a=>{
    const p=$('#'+a.dataset.id);
    a.classList.toggle('hide',t&&!(p.dataset.title+' '+p.textContent).toLowerCase().includes(t));
  });
});
$('#reset').onclick=()=>{if(confirm('Azzerare progresso, checklist e quiz salvati in questo browser?')){Object.keys(localStorage).filter(k=>k.startsWith('limet-guida:')).forEach(k=>localStorage.removeItem(k));location.reload()}};

/* ---------- theme ---------- */
function theme(t){document.documentElement.dataset.theme=t;store.set('theme',t)}
theme(store.get('theme','dark'));
$('#theme').onclick=()=>theme(document.documentElement.dataset.theme==='dark'?'light':'dark');

/* ---------- copy buttons ---------- */
$$('.cmd').forEach(c=>{
  const b=document.createElement('button');b.className='b copy';b.textContent='Copia';
  b.onclick=()=>{const t=c.cloneNode(true);$$('.copy',t).forEach(x=>x.remove());$$('.c',t).forEach(x=>x.remove());
    navigator.clipboard.writeText(t.textContent.split('\n').map(s=>s.trimEnd()).filter(s=>s.trim()).join('\n')).then(()=>{b.textContent='Copiato ✔';setTimeout(()=>b.textContent='Copia',1400)})};
  c.appendChild(b);
});

/* ---------- generic tabs ---------- */
$$('.tabs[data-group]').forEach(tb=>{
  const g=tb.dataset.group;
  const panels=$$('.tabpanel[data-group="'+g+'"]');
  const btns=$$('button',tb);
  function sel(id){btns.forEach(b=>b.classList.toggle('on',b.dataset.tab===id));panels.forEach(p=>p.classList.toggle('hide',p.dataset.id!==id))}
  btns.forEach(b=>b.onclick=()=>sel(b.dataset.tab));
  sel(btns[0].dataset.tab);
});

/* ---------- lifecycle ---------- */
const PH=[
 {n:0,t:'Esplorazione',opt:1,what:'Raccogli contesto e chiarisci il problema <b>prima</b> di formalizzare.',how:'Interroghi Graphify (dove sta il codice) e CEREBRO (cosa dicono le specifiche). Nessun documento obbligatorio.',out:'Una comprensione condivisa tra te e l\'agente.',tpl:'— (uso libero dei context provider)',who:'Agente + tu'},
 {n:1,t:'Proposta',what:'Scrivi <b>perché</b>, <b>cosa</b> cambia e <b>come</b> a grandi linee, prima di toccare il codice.',how:'Modifica piccola: <code>PLAN.md</code>. Modifica ampia (nuova capability, contratto tra componenti, più moduli): <code>CHANGE_PROPOSAL.md</code> (perché) + <code>SPEC.md</code> (cosa, scenari dato/quando/allora) + <code>DESIGN.md</code> opzionale (come).',out:'Un documento di piano con perimetro dentro/fuori scope, alternative scartate e prima bozza della strategia di test.',tpl:'PLAN_TEMPLATE · CHANGE_PROPOSAL_TEMPLATE · SPEC_TEMPLATE · DESIGN_TEMPLATE',who:'Agente scrive, tu approvi'},
 {n:2,t:'Revisione',what:'<b>Tu</b> validi la proposta prima che si scriva una riga di codice.',how:'Ogni ambiguità diventa una <b>domanda contestuale</b> con risposta e data. Se non puoi rispondere subito, l\'agente dichiara l\'assunzione e il rischio.',out:'Piano approvato, domande risolte.',tpl:'Domande contestuali nel piano',who:'Tu (decisione umana)'},
 {n:3,t:'Task',what:'Il piano diventa una lista di passi piccoli e tracciabili.',how:'Una riga per task, con stato <code>pending → in_progress → done</code> (o <code>blocked</code> + motivo). Per i task complessi, una scheda <code>TASK.md</code> dedicata.',out:'<code>TASK_LIST.md</code> con il registro delle modifiche (una riga per file, compilata <i>mentre</i> si lavora).',tpl:'TASK_LIST_TEMPLATE · TASK_TEMPLATE',who:'Agente'},
 {n:4,t:'Applicazione',what:'Si implementa, un task alla volta, aggiornando lo stato.',how:'L\'agente modifica il codice restando nel perimetro. Se serve uscirne, lo segnala. <b>Non esegue build/test né commit/push</b>: ti dà i comandi.',out:'Codice modificato + registro modifiche aggiornato.',tpl:'— (si aggiorna la task list)',who:'Agente'},
 {n:5,t:'Verifica',what:'<b>Obbligatoria.</b> Unit test + (se serve) test end-to-end, con esito reale registrato.',how:'Prima: <code>TEST_PLAN.md</code>. Tu esegui i comandi, incolli l\'esito in <code>TEST_EXECUTION.md</code>. Per integrazioni/UI: <code>E2E_VERIFICATION.md</code> con precondizioni, passi, controllo stato pre/post, rollback.',out:'Test verdi con prova scritta. Solo ora il task può diventare <code>done</code> (data + ora).',tpl:'TEST_PLAN · TEST_EXECUTION · E2E_VERIFICATION',who:'Agente prepara, tu esegui'},
 {n:6,t:'Comunicazione',opt:1,what:'Spieghi l\'esito a chi non è tecnico.',how:'Una pagina: cosa cambia per l\'utente, senza dettagli implementativi.',out:'<code>NON_TECHNICAL_SUMMARY.md</code>',tpl:'NON_TECHNICAL_SUMMARY_TEMPLATE',who:'Agente'},
 {n:7,t:'Archiviazione',what:'Congeli lo storico e aggiorni la documentazione permanente.',how:'Voce di archivio con riferimento al piano, esito finale e documenti aggiornati; la cartella passa da <code>changes/</code> a <code>archive/</code>. Poi <b>tu</b> lanci il Re-index, così la modifica diventa contesto ricercabile.',out:'<code>ARCHIVE_ENTRY.md</code> + indice CEREBRO aggiornato.',tpl:'ARCHIVE_ENTRY_TEMPLATE',who:'Agente + tu (re-index)'}
];
const ph=$('#phases'),pb=$('#phaseBody');
if(ph){
  PH.forEach(p=>{const b=document.createElement('button');b.className=p.opt?'opt':'';b.innerHTML='<span class="n">'+p.n+'</span>'+p.t+(p.opt?'<br><small>(opzionale)</small>':'');b.onclick=()=>sel(p.n);ph.appendChild(b)});
  function sel(n){const p=PH[n];$$('button',ph).forEach((b,i)=>b.classList.toggle('on',i===n));
    pb.innerHTML='<h3>Fase '+p.n+' · '+p.t+(p.opt?' <span class="chip orange">opzionale</span>':'')+'</h3><p><b>Scopo.</b> '+p.what+'</p><p><b>Come.</b> '+p.how+'</p><p><b>Risultato.</b> '+p.out+'</p><p><b>Template:</b> <code>'+p.tpl+'</code></p><p><b>Chi lavora:</b> <span class="chip blue">'+p.who+'</span></p>'}
  sel(1);
}

/* ---------- which tool? ---------- */
const TQ=[
 {q:'Cosa vuoi sapere?',o:[
  ['Dove è implementato qualcosa nel codice / chi lo chiama / cosa rompo se lo modifico','G'],
  ['Perché è stato fatto così / cosa dice la specifica / quale convenzione vale','C'],
  ['Come si comporta davvero il sistema ora (dati, log)','D'],
  ['Devo capire un flusso che attraversa più moduli','M']]}
];
const TR={
 G:['🗺️ Graphify','<code>graphify query "cosa chiama calcolaRata?"</code>, <code>graphify explain NomeClasse</code>, <code>graphify path A B</code>. Costo quasi nullo: analisi locale del codice, nessuna chiamata a modelli esterni.'],
 C:['🧠 CEREBRO','<code>python &lt;CEREBRO&gt;\\scripts\\query_qdrant.py --project &lt;slug&gt; search "&lt;domanda&gt;" --limit 5</code> oppure il tool MCP <code>limet_search</code>. Chiedi in italiano normale, non per parola chiave.'],
 D:['🔎 Accesso dati read-only','Una query SQL o un log, <b>solo in lettura</b>, per verificare un\'ipotesi invece di assumerla dal codice. Mai scrivere sui dati reali.'],
 M:['🗺️ → 🧠 → 📝 In sequenza','Prima Graphify (la struttura), poi CEREBRO (le specifiche), poi <b>incrocia</b> i risultati e scrivi il piano. Se il progetto fa parte di un workspace, consulta anche <code>MODULE_MAP.md</code>.']
};
const tw=$('#toolpick');
if(tw){
  tw.innerHTML='<div class="mini"><b>'+TQ[0].q+'</b></div>';
  TQ[0].o.forEach(([t,k])=>{const b=document.createElement('button');b.className='b';b.style.cssText='display:block;width:100%;text-align:left;margin:8px 0';b.textContent=t;
    b.onclick=()=>{$('#toolres').innerHTML='<div class="callout ok"><b class="t">Usa: '+TR[k][0]+'</b>'+TR[k][1]+'</div>'};tw.appendChild(b)});
}

/* ---------- template chooser ---------- */
const TCH=[
 ['Correggo un difetto puntuale','BUG_REPORT → TASK_LIST (1-2 righe) → TEST_PLAN → TEST_EXECUTION → E2E (se serve) → ARCHIVE_ENTRY','Il bug report contiene la <b>causa radice</b>: il fix deve colpire quella, non il sintomo.'],
 ['Piccola modifica o feature isolata','PLAN → TASK_LIST → TEST_PLAN → TEST_EXECUTION → ARCHIVE_ENTRY','Un solo documento di piano basta se il "come" è ovvio.'],
 ['Feature ampia / cambia un contratto / tocca più moduli','CHANGE_PROPOSAL + SPEC (+ DESIGN) → TASK_LIST → TEST_PLAN → TEST_EXECUTION → E2E_VERIFICATION → NON_TECHNICAL_SUMMARY → ARCHIVE_ENTRY','Separare perché / cosa / come permette di rivedere la specifica senza rifare il disegno.'],
 ['Modifica che attraversa più progetti','CROSS_PROJECT_CHANGE a livello workspace + il flusso normale dentro ogni progetto','Il workspace <b>coordina</b>, il lavoro di dettaglio resta nel <code>limet/</code> di ciascun progetto.'],
 ['Ho scoperto un termine ambiguo','GLOSSARY','Fissa il significato una volta, non in ogni conversazione.']
];
const tc=$('#tplpick');
if(tc){
  TCH.forEach((r,i)=>{const b=document.createElement('button');b.textContent=r[0];b.onclick=()=>{$$('button',tc).forEach(x=>x.classList.toggle('on',x===b));$('#tplres').innerHTML='<div class="callout info"><b class="t">Sequenza consigliata</b><code>'+r[1]+'</code><p style="margin:8px 0 0">'+r[2]+'</p></div>'};tc.appendChild(b);if(!i)b.click()});
}

/* ---------- checklist ---------- */
const CHK=[
 ['Prima di iniziare',['Ho richiamato il contesto di progetto rilevante (docs, istruzioni agente).','Ho verificato se esiste già un piano per questo lavoro.','So se serve un PLAN semplice o la proposta completa (proposal + spec + design).']],
 ['Contesto',['Ho usato Graphify / CEREBRO / dati read-only secondo il criterio di combinazione.','Ho cercato PRIMA in CEREBRO; se non indicizzato, ho letto i docs locali.','Ogni ambiguità è una domanda contestuale scritta, non un\'assunzione.']],
 ['Pianificazione',['Il piano dichiara perimetro dentro/fuori scope.','Le alternative scartate sono documentate.','La strategia di test (unit + e2e) è già abbozzata.']],
 ['Implementazione',['Le modifiche restano nel perimetro (o lo scostamento è approvato).','Nessun commit/push/migrazione/deploy senza mia autorizzazione.','L\'agente non ha eseguito build o test: mi ha dato i comandi.']],
 ['Verifica',['Unit test scritti o estesi per il comportamento modificato.','Autorevisione dei test fatta (sabotaggio mentale, assert che possono fallire).','E2E valutato e, se serve, documentato.','Esito reale registrato in TEST_EXECUTION.']],
 ['Chiusura',['Piano e task aggiornati a ritroso (data, scostamenti).','Sintesi non tecnica prodotta, se rilevante.','Lavoro archiviato (ARCHIVE_ENTRY).','Re-index lanciato da me dal Launcher.']]
];
const cw=$('#chk');
if(cw){
  const st=store.get('chk',{});
  CHK.forEach((g,gi)=>{
    const h=document.createElement('h3');h.textContent=g[0];cw.appendChild(h);
    const box=document.createElement('div');box.className='chk';
    g[1].forEach((t,i)=>{const id=gi+'.'+i;const l=document.createElement('label');l.className=st[id]?'done':'';
      l.innerHTML='<input type="checkbox"'+(st[id]?' checked':'')+'><span>'+t+'</span>';
      l.firstChild.onchange=e=>{st[id]=e.target.checked;l.classList.toggle('done',e.target.checked);store.set('chk',st);upd()};box.appendChild(l)});
    cw.appendChild(box)});
  const total=CHK.reduce((a,g)=>a+g[1].length,0);
  function upd(){const n=Object.values(st).filter(Boolean).length;const pct=Math.round(n/total*100);
    $('#chkPct').textContent=pct+'%';$('#chkTxt').textContent=n+' / '+total+' voci';
    $('#chkRing').setAttribute('stroke-dasharray',(pct*2.513)+' 251.3')}
  $('#chkClear').onclick=()=>{Object.keys(st).forEach(k=>delete st[k]);store.set('chk',st);$$('input',cw).forEach(i=>i.checked=false);$$('label',cw).forEach(l=>l.classList.remove('done'));upd()};
  upd();
}

/* ---------- quiz ---------- */
const QZ=[
 {q:'Un task è "done" quando…',a:['il codice è scritto e compila','esiste una strategia di verifica completata (test eseguiti con esito registrato) o un "non applicabile" motivato','il collega ha fatto la review'],c:1,w:'Scrivere codice non equivale a concludere: serve la prova di verifica (§1.5). Vale solo per modifiche non comportamentali ometterla, e va dichiarato.'},
 {q:'Vuoi sapere "chi chiama calcolaRata() e cosa si rompe se la cambio". Primo strumento?',a:['CEREBRO','Graphify','Chiedere all\'IA di leggere tutto il repo'],c:1,w:'Domanda sul <i>come/dove nel codice</i> → Graphify: costo quasi nullo e relazioni reali, non testo simile.'},
 {q:'Vuoi sapere perché è stata vietata la riassegnazione a certi ruoli. Strumento?',a:['Graphify','grep sul codice','CEREBRO'],c:2,w:'Domanda sul <i>perché</i> / sulla specifica → memoria documentale (CEREBRO).'},
 {q:'L\'agente ha finito di scrivere il fix. Cosa NON deve fare da solo?',a:['Aggiornare TASK_LIST','Lanciare i test e fare commit/push','Proporre il comando di test'],c:1,w:'L\'agente scrive e propone; build, test, commit, push, deploy restano a te (§1.3).'},
 {q:'C\'è un\'ambiguità nei requisiti e nessuno risponde. Cosa fa l\'agente?',a:['Sceglie l\'opzione più probabile in silenzio','La registra come domanda contestuale; se deve procedere, dichiara assunzione e rischio','Si blocca per sempre'],c:1,w:'Mai assumere in silenzio (§1.2): tracciabilità delle decisioni.'},
 {q:'Il piano è cambiato durante l\'implementazione. Cosa si fa?',a:['Si riscrive il piano come se fosse sempre stato così','Si aggiunge una sezione datata "Esito implementazione" con gli scostamenti','Si ignora'],c:1,w:'Non si riscrive la storia: si completa (§1.4).'},
 {q:'Dopo aver modificato documenti o codice, chi lancia il Re-index?',a:['L\'agente, automaticamente','Tu, dal Launcher; l\'agente te lo ricorda','Nessuno: è automatico'],c:1,w:'Il Re-index spetta all\'utente; fino ad allora i documenti locali restano consultabili.'}
];
const qw=$('#quiz');
if(qw){
  let score=0,done=0;
  QZ.forEach((x,i)=>{
    const d=document.createElement('div');d.className='q';
    d.innerHTML='<b>'+(i+1)+'. '+x.q+'</b>';
    x.a.forEach((t,j)=>{const b=document.createElement('button');b.className='opt';b.textContent=t;
      b.onclick=()=>{if(d.classList.contains('answered'))return;d.classList.add('answered');
        $$('.opt',d).forEach((o,k)=>{if(k===x.c)o.classList.add('good');else if(k===j)o.classList.add('bad')});
        done++;if(j===x.c)score++;
        $('#quizRes').textContent=done===QZ.length?('Punteggio finale: '+score+' / '+QZ.length+(score===QZ.length?' — ottimo, sei pronto!':score>=5?' — buono, rivedi le sezioni sbagliate.':' — rileggi le sezioni "Ciclo di vita" e "Verifica".')):('Risposte: '+done+' / '+QZ.length)};
      d.appendChild(b)});
    const w=document.createElement('div');w.className='why';w.innerHTML='💡 '+x.w;d.appendChild(w);qw.appendChild(d)});
}

show(location.hash.slice(1)||pages[0].id);
})();
