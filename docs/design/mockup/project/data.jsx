// ============================================================
// F-BUDDY mock data
// ============================================================

const ACCOUNT_GROUPS = [
  {
    id: "cash", label: "Cash",
    accounts: [
      { id: "checking",  name: "Checking",         balance:  4218.42 },
      { id: "savings",   name: "Savings",          balance: 12450.00 },
      { id: "wallet",    name: "Wallet",           balance:    62.00 },
    ],
  },
  {
    id: "credit", label: "Credit",
    accounts: [
      { id: "visa",      name: "Visa Signature",   balance:  -842.19 },
      { id: "amex",      name: "Amex Everyday",    balance:  -310.55 },
    ],
  },
  {
    id: "loan", label: "Loans",
    accounts: [
      { id: "auto",      name: "Auto Loan",        balance: -8420.00 },
      { id: "student",   name: "Student Loan",     balance:-12100.00 },
    ],
  },
  {
    id: "investment", label: "Investments",
    accounts: [
      { id: "brokerage", name: "Brokerage",        balance: 28430.10 },
      { id: "401k",      name: "401(k)",           balance: 64211.55 },
      { id: "roth",      name: "Roth IRA",         balance: 18900.00 },
    ],
  },
];

const PAYEES = [
  ["Coffee Shop",       "Dining Out",       3.75,  6.50],
  ["Grocery Store",     "Groceries",        42.18, 188.40],
  ["Gas Station",       "Transportation",   28.00, 64.10],
  ["Electric Company",  "Utilities",        88.42, 142.18],
  ["Internet Provider", "Utilities",        65.00, 65.00],
  ["Streaming Service", "Subscriptions",    9.99,  15.99],
  ["Pharmacy",          "Health",           7.40,  44.20],
  ["Hardware Store",    "Home",             18.20, 122.00],
  ["Bookstore",         "Personal",         12.40, 48.00],
  ["Restaurant",        "Dining Out",       16.50, 78.00],
  ["Rideshare",         "Transportation",   8.20,  31.40],
  ["Bakery",            "Dining Out",       4.50,  18.00],
  ["Hardware Store",    "Home",             22.10, 65.00],
  ["Cell Carrier",      "Utilities",        45.00, 75.00],
  ["Gym Membership",    "Health",           29.00, 29.00],
  ["Movie Theater",     "Entertainment",    14.50, 42.00],
  ["Parking Garage",    "Transportation",   6.00,  18.00],
  ["Office Supply",     "Work",             4.20,  82.10],
];

const INFLOW_PAYEES = [
  ["Employer Payroll",  "Income",           1900, 2400],
  ["Side Gig",          "Income",           120,  640],
  ["Refund",            "Income",           4.20, 88.00],
  ["Interest",          "Income",           0.42, 12.10],
];

function seed(s){ let x=s; return ()=>{ x=(x*9301+49297)%233280; return x/233280; }; }

function genTxns(acctId, count){
  const r = seed(acctId.split("").reduce((a,c)=>a+c.charCodeAt(0),0)+count);
  const out = [];
  const today = new Date(2026, 4, 2); // May 2 2026
  for (let i=0;i<count;i++){
    const d = new Date(today); d.setDate(d.getDate() - i*1 - Math.floor(r()*2));
    const isInflow = r() < (acctId === "checking" ? 0.12 : 0.04);
    const pool = isInflow ? INFLOW_PAYEES : PAYEES;
    const [payee, cat, lo, hi] = pool[Math.floor(r()*pool.length)];
    const amt = +(lo + r()*(hi-lo)).toFixed(2);
    const memo = r() < 0.35 ? memoFor(payee, r) : "";
    const status =
      i === 0 ? "uncleared"
      : i < 4 && r() < 0.5 ? "uncleared"
      : r() < 0.06 ? "reconciled"
      : "cleared";
    out.push({
      id: `${acctId}-${i}`,
      date: d,
      status,
      payee,
      category: cat,
      memo,
      outflow: isInflow ? 0 : amt,
      inflow:  isInflow ? amt : 0,
    });
  }
  return out;
}

function memoFor(payee, r){
  const bank = {
    "Coffee Shop":       ["double oat latte", "drip + tip", "morning fix"],
    "Grocery Store":     ["weekly haul", "milk + eggs run", "stocking up"],
    "Gas Station":       ["fillup", "half tank", "premium"],
    "Electric Company":  ["april bill", "autopay", ""],
    "Internet Provider": ["fiber 1G", "autopay", ""],
    "Streaming Service": ["family plan", "annual renewal", ""],
    "Pharmacy":          ["refill", "OTC", ""],
    "Hardware Store":    ["paint + tape", "screws + brackets", "lightbulbs"],
    "Bookstore":         ["used paperback", "gift", ""],
    "Restaurant":        ["birthday dinner", "lunch w/ J", "takeout"],
    "Rideshare":         ["airport", "late night", ""],
    "Bakery":            ["sourdough", "pastries", ""],
    "Cell Carrier":      ["autopay", "data overage", ""],
    "Gym Membership":    ["monthly", "annual", ""],
    "Movie Theater":     ["matinee", "imax", ""],
    "Parking Garage":    ["downtown", "all-day", ""],
    "Office Supply":     ["printer paper", "pens", ""],
    "Employer Payroll":  ["bi-weekly", "bonus", ""],
    "Side Gig":          ["invoice #214", "payout", ""],
    "Refund":            ["return", "rebate", ""],
    "Interest":          ["", "", ""],
  };
  const arr = bank[payee] || [""];
  return arr[Math.floor(r()*arr.length)];
}

const TXNS_BY_ACCT = {};
ACCOUNT_GROUPS.forEach(g => g.accounts.forEach(a => {
  TXNS_BY_ACCT[a.id] = genTxns(a.id, 60);
}));

// Budget data
const BUDGET = [
  { group: "Immediate Obligations", items: [
    { name: "Rent / Mortgage", budgeted: 1450, activity: 1450 },
    { name: "Electric",        budgeted:  120, activity:  138 },
    { name: "Internet",        budgeted:   65, activity:   65 },
    { name: "Cell Phone",      budgeted:   75, activity:   75 },
    { name: "Groceries",       budgeted:  600, activity:  482 },
    { name: "Transportation",  budgeted:  200, activity:  171 },
  ]},
  { group: "True Expenses", items: [
    { name: "Auto Maintenance",budgeted:   80, activity:    0 },
    { name: "Medical",         budgeted:  120, activity:   44 },
    { name: "Renters Insurance",budgeted:  18, activity:   18 },
    { name: "Annual Subs",     budgeted:   40, activity:    0 },
  ]},
  { group: "Quality of Life", items: [
    { name: "Dining Out",      budgeted:  220, activity:  198 },
    { name: "Entertainment",   budgeted:   80, activity:   56 },
    { name: "Hobbies",         budgeted:   60, activity:   30 },
    { name: "Gym",             budgeted:   29, activity:   29 },
  ]},
  { group: "Just for Fun", items: [
    { name: "Coffee",          budgeted:   40, activity:   38 },
    { name: "Books",           budgeted:   30, activity:   12 },
  ]},
];

// Recurring
const RECURRING = [
  { name: "Rent / Mortgage",  amount: -1450, freq: "MONTHLY", next: "2026-05-31", account: "Checking" },
  { name: "Employer Payroll", amount:  2400, freq: "BIWEEKLY", next: "2026-05-15", account: "Checking" },
  { name: "Electric Company", amount:  -120, freq: "MONTHLY", next: "2026-05-12", account: "Checking" },
  { name: "Internet Provider",amount:   -65, freq: "MONTHLY", next: "2026-05-09", account: "Checking" },
  { name: "Streaming Service",amount:   -16, freq: "MONTHLY", next: "2026-05-22", account: "Visa Signature" },
  { name: "Cell Carrier",     amount:   -75, freq: "MONTHLY", next: "2026-05-18", account: "Checking" },
  { name: "Gym Membership",   amount:   -29, freq: "MONTHLY", next: "2026-05-08", account: "Visa Signature" },
  { name: "Auto Loan",        amount:  -340, freq: "MONTHLY", next: "2026-05-20", account: "Checking" },
  { name: "Student Loan",     amount:  -210, freq: "MONTHLY", next: "2026-05-25", account: "Checking" },
];

Object.assign(window, { ACCOUNT_GROUPS, TXNS_BY_ACCT, BUDGET, RECURRING });
