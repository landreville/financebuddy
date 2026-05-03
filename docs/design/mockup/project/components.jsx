// ============================================================
// F-BUDDY shared components
// ============================================================

const { useState, useEffect, useMemo, useRef } = React;

const fmtMoney = (n, opts={}) => {
  const { sign=false, blankZero=false } = opts;
  if (blankZero && (!n || Math.abs(n) < 0.005)) return "";
  const abs = Math.abs(n);
  const s = abs.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  if (sign) return (n < 0 ? "-" : n > 0 ? "+" : " ") + "$" + s;
  return (n < 0 ? "-" : "") + "$" + s;
};

const fmtDate = (d) => {
  const m = String(d.getMonth()+1).padStart(2,"0");
  const day = String(d.getDate()).padStart(2,"0");
  const y = String(d.getFullYear()).slice(2);
  return `${y}-${m}-${day}`;
};

function StatusGlyph({ status, onClick }) {
  const map = {
    cleared:    { cls: "cleared",   ch: "C", title: "Cleared (click to toggle)" },
    uncleared:  { cls: "",          ch: "·", title: "Uncleared (click to toggle)" },
    reconciled: { cls: "recon",     ch: "R", title: "Reconciled" },
  };
  const it = map[status] || map.uncleared;
  return (
    <span className={`st ${it.cls}`} title={it.title} onClick={onClick}>{it.ch}</span>
  );
}

// ============================================================
// HEADER
// ============================================================
function Header({ screen, setScreen }) {
  const items = ["Dashboard","Budget","Accounts","Reports","Recurring"];
  const [now, setNow] = useState(new Date());
  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(t);
  }, []);
  const time = now.toLocaleTimeString("en-US", { hour12: false });
  return (
    <header className="hdr">
      <div className="hdr__brand">
        <div className="hdr__mark">F</div>
        <div>
          <div className="hdr__name">F-BUDDY</div>
          <div className="hdr__tag">F as in Finance</div>
        </div>
      </div>
      <nav className="hdr__nav">
        {items.map(it => (
          <button
            key={it}
            className={screen === it ? "is-active" : ""}
            onClick={() => setScreen(it)}
          >{it}</button>
        ))}
      </nav>
      <div className="hdr__right">
        <span className="dot" /> ONLINE
        <span style={{opacity:0.5}}>·</span>
        <span>{time} UTC</span>
      </div>
    </header>
  );
}

// ============================================================
// SIDEBAR
// ============================================================
function Sidebar({ activeAcct, setActiveAcct }) {
  const groups = window.ACCOUNT_GROUPS;
  const groupTotal = (g) => g.accounts.reduce((s,a)=>s+a.balance,0);
  const cashTotal = useMemo(() => {
    let t = 0;
    groups.forEach(g => g.accounts.forEach(a => { t += a.balance; }));
    return t;
  }, []);
  return (
    <aside className="side" data-screen-label="sidebar">
      <div className="side__head">
        <span>Accounts</span>
        <span style={{opacity:0.6}}>＋ NEW</span>
      </div>
      <div className="side__net">
        <div className="lbl">NET WORTH</div>
        <div className="val">{fmtMoney(cashTotal)}</div>
      </div>
      <div className="side__scroll">
        {groups.map(g => (
          <div className="side__group" key={g.id}>
            <h4>
              <span><span className="chev">▼</span> {g.label}</span>
              <span className="total">{fmtMoney(groupTotal(g))}</span>
            </h4>
            {g.accounts.map(a => (
              <div
                key={a.id}
                className={`side__acct ${activeAcct === a.id ? "is-active" : ""}`}
                onClick={() => setActiveAcct(a.id)}
              >
                <span className="name">{a.name}</span>
                <span className={`bal ${a.balance < 0 ? "neg" : ""}`}>
                  {fmtMoney(a.balance)}
                </span>
              </div>
            ))}
          </div>
        ))}
      </div>
    </aside>
  );
}

// ============================================================
// STATUS BAR
// ============================================================
function StatusBar({ screen, activeAcct, txnCount, glitchOn }) {
  const acct = useMemo(() => {
    for (const g of window.ACCOUNT_GROUPS)
      for (const a of g.accounts) if (a.id === activeAcct) return a;
    return null;
  }, [activeAcct]);
  return (
    <div className="statusbar">
      <span>● READY</span>
      <span className="blink">SCREEN: {screen.toUpperCase()} {acct ? `/ ${acct.name.toUpperCase()}` : ""}</span>
      <span>TX: {txnCount}</span>
      <span>SYNC: 02 MAY 2026 09:42</span>
      <span>v0.4.2-cyber</span>
    </div>
  );
}

Object.assign(window, { fmtMoney, fmtDate, StatusGlyph, Header, Sidebar, StatusBar });
