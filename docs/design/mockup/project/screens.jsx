// ============================================================
// F-BUDDY screens
// ============================================================

const { useState: useStateS, useMemo: useMemoS, useEffect: useEffectS } = React;

// ============================================================
// ACCOUNTS  (the hero)
// ============================================================
function AccountsScreen({ activeAcct }) {
  const [txns, setTxns] = useStateS(() => window.TXNS_BY_ACCT[activeAcct] || []);
  const [selected, setSelected] = useStateS(null);
  const [query, setQuery] = useStateS("");

  useEffectS(() => {
    setTxns(window.TXNS_BY_ACCT[activeAcct] || []);
    setSelected(null);
  }, [activeAcct]);

  const acct = useMemoS(() => {
    for (const g of window.ACCOUNT_GROUPS)
      for (const a of g.accounts) if (a.id === activeAcct) return a;
    return null;
  }, [activeAcct]);

  const filtered = useMemoS(() => {
    if (!query) return txns;
    const q = query.toLowerCase();
    return txns.filter(t =>
      t.payee.toLowerCase().includes(q) ||
      t.category.toLowerCase().includes(q) ||
      (t.memo || "").toLowerCase().includes(q)
    );
  }, [txns, query]);

  const cleared = txns.filter(t => t.status !== "uncleared")
    .reduce((s,t)=>s + t.inflow - t.outflow, 0);
  const uncleared = txns.filter(t => t.status === "uncleared")
    .reduce((s,t)=>s + t.inflow - t.outflow, 0);

  const toggleStatus = (id) => {
    setTxns(prev => prev.map(t => t.id === id
      ? { ...t, status: t.status === "cleared" ? "uncleared" : "cleared" }
      : t
    ));
  };

  return (
    <div className="main" data-screen-label="accounts">
      <div className="main__head">
        <div>
          <h1 className="main__title">{acct ? acct.name : "—"}</h1>
          <div className="main__sub">// Working Balance · {fmtMoney(acct ? acct.balance : 0)}</div>
        </div>
        <div className="main__balrow">
          <div className="main__balcell cleared">
            <div className="lbl">Cleared</div>
            <div className="val">{fmtMoney(cleared)}</div>
          </div>
          <div className="main__balcell uncleared">
            <div className="lbl">Uncleared</div>
            <div className="val">{fmtMoney(uncleared)}</div>
          </div>
          <div className="main__balcell">
            <div className="lbl">Working</div>
            <div className="val">{fmtMoney(acct ? acct.balance : 0)}</div>
          </div>
        </div>
      </div>

      <div className="tb">
        <button className="btn btn--primary">＋ ADD TXN</button>
        <button className="btn">EDIT</button>
        <button className="btn">FILE ▾</button>
        <input
          type="text"
          placeholder="search payees, memos, categories..."
          value={query}
          onChange={e => setQuery(e.target.value)}
        />
        <div className="spacer" />
        <span className="meta">{filtered.length} of {txns.length} rows</span>
        <button className="btn">⇩ EXPORT</button>
        <button className="btn">⟳ RECONCILE</button>
      </div>

      <div className="ledger">
        <table>
          <colgroup>
            <col className="col-status" />
            <col className="col-date" />
            <col className="col-payee" />
            <col className="col-cat" />
            <col className="col-memo" />
            <col className="col-out" />
            <col className="col-in" />
          </colgroup>
          <thead>
            <tr>
              <th className="col-status">✓</th>
              <th className="col-date">DATE</th>
              <th className="col-payee">PAYEE</th>
              <th className="col-cat">CATEGORY</th>
              <th className="col-memo">MEMO</th>
              <th className="col-out" style={{textAlign:"right"}}>OUTFLOW</th>
              <th className="col-in"  style={{textAlign:"right"}}>INFLOW</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(t => (
              <tr
                key={t.id}
                className={`${selected === t.id ? "is-selected glitchy" : ""}`}
                onClick={() => setSelected(t.id)}
              >
                <td className="col-status">
                  <StatusGlyph status={t.status} onClick={(e) => { e.stopPropagation(); toggleStatus(t.id); }} />
                </td>
                <td className="col-date">{fmtDate(t.date)}</td>
                <td className="col-payee">{t.payee}</td>
                <td className="col-cat">{t.category}</td>
                <td className="col-memo">{t.memo}</td>
                <td className={`col-out ${t.outflow ? "has" : ""}`}>{fmtMoney(t.outflow, {blankZero:true})}</td>
                <td className={`col-in  ${t.inflow  ? "has" : ""}`}>{fmtMoney(t.inflow,  {blankZero:true})}</td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan="7" style={{padding:"24px", textAlign:"center", color:"var(--muted)"}}>
                — NO TRANSACTIONS MATCH —
              </td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ============================================================
// DASHBOARD (lo-fi)
// ============================================================
function DashboardScreen() {
  const totals = useMemoS(() => {
    let cash=0, credit=0, loan=0, invest=0;
    for (const g of window.ACCOUNT_GROUPS) {
      const sum = g.accounts.reduce((s,a)=>s+a.balance,0);
      if (g.id==="cash") cash=sum;
      if (g.id==="credit") credit=sum;
      if (g.id==="loan") loan=sum;
      if (g.id==="investment") invest=sum;
    }
    return { cash, credit, loan, invest, net: cash+credit+loan+invest };
  }, []);

  return (
    <div className="main" data-screen-label="dashboard" style={{overflow:"auto"}}>
      <div className="main__head">
        <div>
          <h1 className="main__title">Dashboard</h1>
          <div className="main__sub">// Snapshot · 02 May 2026</div>
        </div>
      </div>

      <div className="kpi">
        {[
          ["Net Worth",   totals.net,    "blue"],
          ["Cash",        totals.cash,   "blue"],
          ["Credit",      totals.credit, "red"],
          ["Investments", totals.invest, "blue"],
        ].map(([l,v,c]) => (
          <div className="panel" key={l}>
            <div className="l">{l}</div>
            <div className="v" style={{color: v < 0 ? "var(--red)" : "var(--ink)"}}>{fmtMoney(v)}</div>
          </div>
        ))}
      </div>

      <div style={{display:"grid", gridTemplateColumns:"1fr 1fr", gap:"12px", padding:"0 12px 12px"}}>
        <div className="panel">
          <div className="panel__h"><span>SPENDING / 30 DAYS</span><span>BY CATEGORY</span></div>
          <div className="panel__b">
            <CategoryBars />
          </div>
        </div>
        <div className="panel">
          <div className="panel__h"><span>NET WORTH / 12 MONTHS</span><span>▲ +4.2%</span></div>
          <div className="panel__b">
            <Sparkline />
          </div>
        </div>
      </div>

      <div style={{padding:"0 12px 12px"}}>
        <div className="panel">
          <div className="panel__h"><span>RECENT ACTIVITY</span><span>LAST 8</span></div>
          <div style={{padding:"0"}}>
            <table style={{width:"100%", borderCollapse:"collapse", fontSize:"var(--fz-md)"}}>
              <tbody>
                {window.TXNS_BY_ACCT.checking.slice(0,8).map(t => (
                  <tr key={t.id} style={{borderBottom:"1px dashed #DDDDDD"}}>
                    <td style={{padding:"5px 10px", width:90, color:"var(--muted)"}}>{fmtDate(t.date)}</td>
                    <td style={{padding:"5px 10px"}}>{t.payee}</td>
                    <td style={{padding:"5px 10px", color:"var(--blue)"}}>{t.category}</td>
                    <td style={{padding:"5px 10px", textAlign:"right", fontVariantNumeric:"tabular-nums",
                      color: t.outflow ? "var(--red)" : "var(--blue)"}}>
                      {t.outflow ? `-${fmtMoney(t.outflow)}` : `+${fmtMoney(t.inflow)}`}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}

function CategoryBars(){
  const cats = [
    ["Groceries",      482, 600],
    ["Dining Out",     198, 220],
    ["Transportation", 171, 200],
    ["Utilities",      278, 280],
    ["Entertainment",   56,  80],
    ["Health",          44, 120],
  ];
  return (
    <div style={{display:"grid", gap:8}}>
      {cats.map(([n, v, b]) => {
        const pct = Math.min(100, (v / b) * 100);
        return (
          <div key={n} style={{display:"grid", gridTemplateColumns:"130px 1fr 80px", gap:10, alignItems:"center"}}>
            <div style={{fontSize:"var(--fz-sm)"}}>{n}</div>
            <div className={`bar ${v > b ? "over" : ""}`}><span style={{width: pct+"%"}} /></div>
            <div style={{fontSize:"var(--fz-sm)", textAlign:"right", fontVariantNumeric:"tabular-nums"}}>
              ${v}/${b}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function Sparkline(){
  const pts = [82,84,83,86,89,88,91,93,92,95,97,99];
  const w = 360, h = 130, pad = 6;
  const max = Math.max(...pts), min = Math.min(...pts);
  const xs = (i) => pad + i * ((w - pad*2) / (pts.length - 1));
  const ys = (v) => h - pad - ((v - min) / (max - min)) * (h - pad*2);
  const path = pts.map((v,i) => `${i===0?"M":"L"} ${xs(i)} ${ys(v)}`).join(" ");
  return (
    <svg viewBox={`0 0 ${w} ${h}`} style={{width:"100%", height:140, border:"1px solid var(--ink)", background:"var(--paper)"}}>
      {/* grid */}
      {[0,1,2,3].map(i => (
        <line key={i} x1={pad} x2={w-pad} y1={pad + i*((h-pad*2)/3)} y2={pad + i*((h-pad*2)/3)}
          stroke="#CCCCCC" strokeDasharray="2 3" />
      ))}
      <path d={path} fill="none" stroke="#0046A8" strokeWidth="2" />
      <path d={`${path} L ${xs(pts.length-1)} ${h-pad} L ${xs(0)} ${h-pad} Z`} fill="#0046A833" />
      {pts.map((v,i)=>(
        <rect key={i} x={xs(i)-2} y={ys(v)-2} width="4" height="4" fill="#C2272D" />
      ))}
    </svg>
  );
}

// ============================================================
// BUDGET
// ============================================================
function BudgetScreen() {
  const totalBudgeted = window.BUDGET.flatMap(g=>g.items).reduce((s,i)=>s+i.budgeted, 0);
  const totalActivity = window.BUDGET.flatMap(g=>g.items).reduce((s,i)=>s+i.activity, 0);
  return (
    <div className="main" data-screen-label="budget" style={{overflow:"auto"}}>
      <div className="main__head">
        <div>
          <h1 className="main__title">Budget · May 2026</h1>
          <div className="main__sub">// To Be Assigned · {fmtMoney(0)}</div>
        </div>
        <div className="main__balrow">
          <div className="main__balcell"><div className="lbl">Budgeted</div><div className="val">{fmtMoney(totalBudgeted)}</div></div>
          <div className="main__balcell"><div className="lbl">Activity</div><div className="val">{fmtMoney(-totalActivity)}</div></div>
          <div className="main__balcell cleared"><div className="lbl">Available</div><div className="val">{fmtMoney(totalBudgeted-totalActivity)}</div></div>
        </div>
      </div>

      <div className="tb">
        <button className="btn">‹ APR</button>
        <button className="btn is-active">MAY 2026</button>
        <button className="btn">JUN ›</button>
        <div className="spacer" />
        <button className="btn">＋ CATEGORY GROUP</button>
        <button className="btn btn--primary">ASSIGN MONEY</button>
      </div>

      <div className="ledger">
        <table>
          <colgroup>
            <col style={{width:"38%"}}/><col style={{width:"20%"}}/><col style={{width:"20%"}}/><col style={{width:"22%"}}/>
          </colgroup>
          <thead>
            <tr>
              <th>CATEGORY</th>
              <th style={{textAlign:"right"}}>BUDGETED</th>
              <th style={{textAlign:"right"}}>ACTIVITY</th>
              <th>AVAILABLE</th>
            </tr>
          </thead>
          <tbody>
            {window.BUDGET.map(g => (
              <React.Fragment key={g.group}>
                <tr><td colSpan="4" style={{
                  background:"var(--paper-2)", textTransform:"uppercase", letterSpacing:"1.5px",
                  fontSize:"var(--fz-xs)", padding:"6px 10px", borderTop:"1px solid var(--ink)",
                  borderBottom:"1px solid var(--ink)", fontWeight:700
                }}>▼ {g.group}</td></tr>
                {g.items.map(it => {
                  const avail = it.budgeted - it.activity;
                  const pct = it.budgeted ? Math.min(100, (it.activity / it.budgeted) * 100) : 0;
                  const over = it.activity > it.budgeted;
                  return (
                    <tr key={it.name}>
                      <td>{it.name}</td>
                      <td style={{textAlign:"right", fontVariantNumeric:"tabular-nums"}}>{fmtMoney(it.budgeted)}</td>
                      <td style={{textAlign:"right", fontVariantNumeric:"tabular-nums", color: it.activity ? "var(--red)" : "var(--muted)"}}>
                        {it.activity ? `-${fmtMoney(it.activity)}` : "—"}
                      </td>
                      <td>
                        <div style={{display:"grid", gridTemplateColumns:"1fr 80px", gap:8, alignItems:"center"}}>
                          <div className={`bar ${over ? "over" : ""}`}><span style={{width: pct+"%"}}/></div>
                          <span style={{textAlign:"right", fontVariantNumeric:"tabular-nums",
                            color: avail < 0 ? "var(--red)" : "var(--blue)", fontWeight: 700}}>
                            {fmtMoney(avail)}
                          </span>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ============================================================
// REPORTS
// ============================================================
function ReportsScreen() {
  return (
    <div className="main" data-screen-label="reports" style={{overflow:"auto"}}>
      <div className="main__head">
        <div>
          <h1 className="main__title">Reports</h1>
          <div className="main__sub">// Income / Expense · YTD 2026</div>
        </div>
        <div className="main__balrow">
          <div className="main__balcell cleared"><div className="lbl">Income</div><div className="val">{fmtMoney(24820)}</div></div>
          <div className="main__balcell uncleared"><div className="lbl">Expense</div><div className="val">{fmtMoney(-18342)}</div></div>
          <div className="main__balcell"><div className="lbl">Net</div><div className="val">{fmtMoney(6478)}</div></div>
        </div>
      </div>

      <div className="tb">
        <button className="btn is-active">INCOME / EXPENSE</button>
        <button className="btn">SPENDING TRENDS</button>
        <button className="btn">NET WORTH</button>
        <button className="btn">CASH FLOW</button>
        <div className="spacer" />
        <span className="meta">Range: JAN–MAY 2026</span>
      </div>

      <div style={{padding:12, display:"grid", gridTemplateColumns:"1fr 1fr", gap:12}}>
        <div className="panel">
          <div className="panel__h"><span>MONTHLY NET</span><span>JAN–MAY</span></div>
          <div className="panel__b">
            <BarChart data={[
              ["JAN", 1240], ["FEB", 1580], ["MAR", 980], ["APR", 1420], ["MAY", 1258]
            ]} />
          </div>
        </div>

        <div className="panel">
          <div className="panel__h"><span>EXPENSE MIX</span><span>YTD</span></div>
          <div className="panel__b">
            <ExpenseMix />
          </div>
        </div>

        <div className="panel" style={{gridColumn:"1 / -1"}}>
          <div className="panel__h"><span>CATEGORY DETAIL</span><span>YTD 2026</span></div>
          <table style={{width:"100%", borderCollapse:"collapse", fontSize:"var(--fz-md)"}}>
            <thead>
              <tr style={{background:"var(--paper-2)", borderBottom:"1px solid var(--ink)"}}>
                <th style={{textAlign:"left", padding:"6px 10px", textTransform:"uppercase", letterSpacing:"1px", fontSize:"var(--fz-xs)"}}>Category</th>
                <th style={{textAlign:"right", padding:"6px 10px", textTransform:"uppercase", letterSpacing:"1px", fontSize:"var(--fz-xs)"}}>Jan</th>
                <th style={{textAlign:"right", padding:"6px 10px", textTransform:"uppercase", letterSpacing:"1px", fontSize:"var(--fz-xs)"}}>Feb</th>
                <th style={{textAlign:"right", padding:"6px 10px", textTransform:"uppercase", letterSpacing:"1px", fontSize:"var(--fz-xs)"}}>Mar</th>
                <th style={{textAlign:"right", padding:"6px 10px", textTransform:"uppercase", letterSpacing:"1px", fontSize:"var(--fz-xs)"}}>Apr</th>
                <th style={{textAlign:"right", padding:"6px 10px", textTransform:"uppercase", letterSpacing:"1px", fontSize:"var(--fz-xs)"}}>May</th>
                <th style={{textAlign:"right", padding:"6px 10px", textTransform:"uppercase", letterSpacing:"1px", fontSize:"var(--fz-xs)"}}>Total</th>
              </tr>
            </thead>
            <tbody>
              {[
                ["Groceries",        [520,498,612,545,482]],
                ["Dining Out",       [180,220,165,210,198]],
                ["Transportation",   [144,180,210,165,171]],
                ["Utilities",        [285,278,302,290,278]],
                ["Entertainment",    [62, 88, 44, 92, 56]],
                ["Health",           [120,40, 88, 32, 44]],
                ["Subscriptions",    [56, 56, 71, 56, 56]],
              ].map(([n, vals]) => {
                const tot = vals.reduce((a,b)=>a+b,0);
                return (
                  <tr key={n} style={{borderBottom:"1px dashed #DDDDDD"}}>
                    <td style={{padding:"5px 10px"}}>{n}</td>
                    {vals.map((v,i)=>(
                      <td key={i} style={{textAlign:"right", padding:"5px 10px", fontVariantNumeric:"tabular-nums"}}>
                        {fmtMoney(v)}
                      </td>
                    ))}
                    <td style={{textAlign:"right", padding:"5px 10px", fontVariantNumeric:"tabular-nums", fontWeight:700}}>{fmtMoney(tot)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function BarChart({ data }){
  const max = Math.max(...data.map(d=>d[1]));
  const w = 360, h = 180, pad = 24;
  const bw = (w - pad*2) / data.length - 8;
  return (
    <svg viewBox={`0 0 ${w} ${h}`} style={{width:"100%", height:200, border:"1px solid var(--ink)", background:"var(--paper)"}}>
      {data.map(([l,v], i) => {
        const x = pad + i*((w - pad*2)/data.length) + 4;
        const bh = ((v / max) * (h - pad*2));
        const y = h - pad - bh;
        return (
          <g key={l}>
            <rect x={x} y={y} width={bw} height={bh} fill="#0046A8" />
            <rect x={x+3} y={y-3} width={bw} height={bh} fill="none" stroke="#C2272D" />
            <text x={x + bw/2} y={h-8} textAnchor="middle" fontSize="10" fill="#111" fontFamily="JetBrains Mono">{l}</text>
            <text x={x + bw/2} y={y-6} textAnchor="middle" fontSize="10" fill="#111" fontFamily="JetBrains Mono">{v}</text>
          </g>
        );
      })}
      <line x1={pad} x2={w-pad} y1={h-pad} y2={h-pad} stroke="#111" />
    </svg>
  );
}

function ExpenseMix(){
  const data = [
    ["Housing",     1450, "#0046A8"],
    ["Groceries",    482, "#C2272D"],
    ["Utilities",    278, "#111111"],
    ["Dining",       198, "#0046A8"],
    ["Transport",    171, "#C2272D"],
    ["Other",        220, "#6B6B6B"],
  ];
  const total = data.reduce((s,d)=>s+d[1],0);
  let acc = 0;
  return (
    <div>
      <div style={{display:"flex", border:"1px solid var(--ink)", height:24, marginBottom:10}}>
        {data.map(([n,v,c]) => (
          <div key={n} title={`${n}: ${fmtMoney(v)}`}
            style={{width: (v/total*100)+"%", background:c, borderRight:"1px solid var(--paper)"}} />
        ))}
      </div>
      <div style={{display:"grid", gridTemplateColumns:"1fr 1fr", gap:6}}>
        {data.map(([n,v,c]) => (
          <div key={n} style={{display:"flex", alignItems:"center", gap:8, fontSize:"var(--fz-sm)"}}>
            <span style={{width:12, height:12, background:c, border:"1px solid var(--ink)"}} />
            <span style={{flex:1}}>{n}</span>
            <span style={{fontVariantNumeric:"tabular-nums"}}>{fmtMoney(v)}</span>
            <span style={{color:"var(--muted)", width:42, textAlign:"right"}}>{(v/total*100).toFixed(0)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ============================================================
// RECURRING
// ============================================================
function RecurringScreen() {
  const monthly = window.RECURRING.reduce((s,r)=> s + (r.freq === "BIWEEKLY" ? r.amount * 2 : r.amount), 0);
  return (
    <div className="main" data-screen-label="recurring" style={{overflow:"auto"}}>
      <div className="main__head">
        <div>
          <h1 className="main__title">Recurring</h1>
          <div className="main__sub">// Scheduled · Auto-detected from history</div>
        </div>
        <div className="main__balrow">
          <div className="main__balcell"><div className="lbl">Inflow / mo</div><div className="val" style={{color:"var(--blue)"}}>{fmtMoney(4800)}</div></div>
          <div className="main__balcell"><div className="lbl">Outflow / mo</div><div className="val" style={{color:"var(--red)"}}>{fmtMoney(-2305)}</div></div>
          <div className="main__balcell"><div className="lbl">Net / mo</div><div className="val">{fmtMoney(monthly)}</div></div>
        </div>
      </div>

      <div className="tb">
        <button className="btn is-active">ALL</button>
        <button className="btn">BILLS</button>
        <button className="btn">INCOME</button>
        <button className="btn">SUBSCRIPTIONS</button>
        <div className="spacer" />
        <button className="btn">＋ NEW SCHEDULE</button>
      </div>

      <div className="ledger">
        <table>
          <thead>
            <tr>
              <th style={{width:30}}>✓</th>
              <th>NAME</th>
              <th>ACCOUNT</th>
              <th>FREQUENCY</th>
              <th>NEXT</th>
              <th style={{textAlign:"right"}}>AMOUNT</th>
            </tr>
          </thead>
          <tbody>
            {window.RECURRING.map((r,i) => (
              <tr key={i}>
                <td><span className="st cleared">✓</span></td>
                <td>{r.name}</td>
                <td style={{color:"var(--blue)"}}>{r.account}</td>
                <td style={{color:"var(--muted)", letterSpacing:"1px", fontSize:"var(--fz-xs)"}}>{r.freq}</td>
                <td style={{fontVariantNumeric:"tabular-nums"}}>{r.next}</td>
                <td style={{textAlign:"right", fontVariantNumeric:"tabular-nums", color: r.amount < 0 ? "var(--red)" : "var(--blue)", fontWeight: 700}}>
                  {fmtMoney(r.amount, {sign:true})}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

Object.assign(window, { AccountsScreen, DashboardScreen, BudgetScreen, ReportsScreen, RecurringScreen });
