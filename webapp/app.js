/* Pet Park web app — reads pets straight from the blockchain and lets students care for them.
 * No server, no build step: a static site. Settings: config.js (URL parameters override it).
 * Pixel pets and the Tamagotchi device are the same drawings as the workshop slides. */
"use strict";

// ---------------------------------------------------------------- networks
const NETWORKS = {
  optimism:       { label: "OP Mainnet",   chainId: 10,       currency: "ETH",  rpc: "https://mainnet.optimism.io",                 explorer: "https://optimistic.etherscan.io",      pollMs: 4000, replayBlocks: 1500, maxRange: 500 },
  base:           { label: "Base",         chainId: 8453,     currency: "ETH",  rpc: "https://base-rpc.publicnode.com",             explorer: "https://basescan.org",                 pollMs: 4000, replayBlocks: 1500, maxRange: 500 },
  xdc:            { label: "XDC Network",  chainId: 50,       currency: "XDC",  rpc: "https://rpc.xdcrpc.com",                      explorer: "https://xdcscan.com",                  pollMs: 4000, replayBlocks: 1500, maxRange: 500 },
  gnosis:         { label: "Gnosis",       chainId: 100,      currency: "xDAI", rpc: "https://rpc.gnosischain.com",                 explorer: "https://gnosis.blockscout.com",        pollMs: 5000, replayBlocks: 700,  maxRange: 700 },
  celo:           { label: "Celo",         chainId: 42220,    currency: "CELO", rpc: "https://forno.celo.org",                      explorer: "https://celo.blockscout.com",          pollMs: 4000, replayBlocks: 3000, maxRange: 1000 },
  "celo-sepolia": { label: "Celo Sepolia", chainId: 11142220, currency: "CELO", rpc: "https://forno.celo-sepolia.celo-testnet.org", explorer: "https://celo-sepolia.blockscout.com", pollMs: 4000, replayBlocks: 3000, maxRange: 1000 },
  local:          { label: "Local",        chainId: 31337,    currency: "ETH",  rpc: "http://127.0.0.1:8545",                       explorer: "",                                     pollMs: 3000, replayBlocks: 2000, maxRange: 5000 },
};
const params = new URLSearchParams(location.search);
const store = { get(k) { try { return localStorage.getItem(k); } catch { return null; } },
                set(k, v) { try { localStorage.setItem(k, v); } catch {} } };
const CFG = {
  network: params.get("network") || window.PETPARK_CONFIG?.network || store.get("network") || "optimism",
  park: params.get("park") || window.PETPARK_CONFIG?.park || store.get("park") || "",
  rpc: params.get("rpc") || window.PETPARK_CONFIG?.rpc || "",
};
const NET = NETWORKS[CFG.network];

// ---------------------------------------------------------------- contracts
const PARK_ABI = [
  "function snack() view returns (address)",
  "function allPets() view returns (address[])",
  "function dripAmount() view returns (uint256)",
  "function secondsUntilClaim(address) view returns (uint256)",
  "function claim()",
  "event Claimed(address indexed who, uint256 amount)",
  "event PetRegistered(address indexed pet)",
];
const SNACK_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function allowance(address owner, address spender) view returns (uint256)",
  "function approve(address spender, uint256 value) returns (bool)",
];
// Everything any code-along step (or challenge) may have. A pet only answers what it has.
const PET_ABI = [
  "function name() view returns (string)", "function owner() view returns (address)", "function birthday() view returns (uint256)",
  "function hugs() view returns (uint256)", "function lastFed() view returns (uint256)", "function lastPlayed() view returns (uint256)",
  "function lastSlept() view returns (uint256)", "function sleepingUntil() view returns (uint256)",
  "function FEED_COST() view returns (uint256)", "function PLAY_COST() view returns (uint256)", "function REVIVE_COST() view returns (uint256)",
  "function HUNGER_PER_MINUTE() view returns (uint256)", "function BOREDOM_PER_MINUTE() view returns (uint256)",
  "function TIREDNESS_PER_MINUTE() view returns (uint256)", "function NAP_TIME() view returns (uint256)",
  "function hunger() view returns (uint256)", "function boredom() view returns (uint256)", "function tiredness() view returns (uint256)",
  "function mood() view returns (string)", "function poops() view returns (uint256)", "function level() view returns (uint256)",
  "function bestFriend() view returns (address)",
  "function hug()", "function feed()", "function play()", "function sleep()", "function revive()", "function clean()",
  "event Born(string name, address indexed owner)", "event Fed(address indexed by)", "event Played(address indexed by)",
  "event Slept(uint256 until)", "event Hugged(address indexed by, uint256 totalHugs)", "event Revived(address indexed by)",
  "event Cleaned(address indexed by)", "event LevelUp(uint256 level)",
];
const petI = new ethers.Interface(PET_ABI), parkI = new ethers.Interface(PARK_ABI), snackI = new ethers.Interface(SNACK_ABI);
const logI = new ethers.Interface([...PET_ABI, ...PARK_ABI]);
const EVENT_TOPICS = ["Born", "Fed", "Played", "Slept", "Hugged", "Revived", "Cleaned", "LevelUp", "Claimed"].map((n) => logI.getEvent(n).topicHash);
const IDENTITY = ["name", "owner", "birthday", "FEED_COST", "PLAY_COST", "REVIVE_COST", "HUNGER_PER_MINUTE", "BOREDOM_PER_MINUTE", "TIREDNESS_PER_MINUTE", "NAP_TIME"];
const LIVE = ["hugs", "lastFed", "lastPlayed", "lastSlept", "sleepingUntil", "hunger", "boredom", "tiredness", "mood", "poops", "level", "bestFriend"];
const ACTIONS = [
  { fn: "feed",   label: "Feed",       fx: "🍙", fxKind: "drop",   cost: "FEED_COST",   owner: false, device: "a", does: "hunger back to 0" },
  { fn: "play",   label: "Play",       fx: "⚽", fxKind: "bounce", cost: "PLAY_COST",   owner: false, device: "b", does: "boredom back to 0" },
  { fn: "hug",    label: "Hug",        fx: "❤️", fxKind: "up",     cost: null,          owner: false, device: "c", does: "+1 hug" },
  { fn: "sleep",  label: "Put to bed", fx: "💤", fxKind: "up",     cost: null,          owner: true,  does: "a nap, tiredness back to 0" },
  { fn: "clean",  label: "Clean up",   fx: "🧽", fxKind: "up",     cost: null,          owner: false, does: "no more poop" },
  { fn: "revive", label: "Revive",     fx: "✨", fxKind: "up",     cost: "REVIVE_COST", owner: true,  does: "back to life" },
];
const FX = { Fed: ["🍙", "drop"], Played: ["⚽", "bounce"], Hugged: ["❤️", "up"], Slept: ["💤", "up"], Revived: ["✨", "up"], Born: ["✨", "up"], Cleaned: ["🧽", "up"], LevelUp: ["⭐", "up"] };

// ---------------------------------------------------------------- state
let read, snackAddr, chainOffset = 0, blockNumber = 0, parkBank = 0n, lastBlock = 0, rpcOk = true, firstLoad = true;
const pets = new Map();            // address -> pet
const feed = [];                   // activity feed entries
const localFx = new Map();         // pet+event -> time we already animated it locally (avoid doubles)
const wallet = { account: null, chainOk: false, coin: 0n, snack: 0n, claimAt: 0, allowance: new Map(), busy: false };
let route = { name: "park" };

// ---------------------------------------------------------------- small helpers
const $ = (s, el = document) => el.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const short = (a) => (a ? `${a.slice(0, 6)}…${a.slice(-4)}` : "?");
const same = (a, b) => !!a && !!b && a.toLowerCase() === b.toLowerCase();
const now = () => Date.now() / 1000 + chainOffset;
const num = (v) => (v === undefined || v === null ? undefined : Number(v));
const xlink = (kind, v, text) => (NET.explorer ? `<a href="${NET.explorer}/${kind}/${v}" target="_blank" rel="noopener">${text}</a>` : "");
function dur(sec) {
  sec = Math.max(0, Math.floor(sec));
  const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60;
  return h ? `${h} h ${String(m).padStart(2, "0")} min` : `${m}:${String(s).padStart(2, "0")}`;
}
function ageText(p) {
  const m = Math.max(0, Math.floor((now() - (p.birthday || now())) / 60));
  if (m < 60) return `${m} min old`;
  if (m < 2880) return `${Math.floor(m / 60)} h ${m % 60} min old`;
  return `${Math.floor(m / 1440)} days old`;
}
// 2.5 -> "2.5", 0.000299 -> "0.000299": small ETH amounts keep 3 significant digits
const coin = (wei) => { const v = Number(ethers.formatEther(wei)); return v >= 1 ? v.toLocaleString(undefined, { maximumFractionDigits: 3 }) : v.toLocaleString(undefined, { maximumSignificantDigits: 3 }); };

// ---------------------------------------------------------------- pixel pets (same drawings as the slides)
const BODY = ["....XXXXXX....", "..XXXXXXXXXX..", ".XXXXXXXXXXXX.", ".XXXXXXXXXXXX.", "XXXXXXXXXXXXXX", "XXXXXXXXXXXXXX",
              "XXXXXXXXXXXXXX", "XXXXXXXXXXXXXX", ".XXXXXXXXXXXX.", ".XXXXXXXXXXXX.", "..XX......XX.."];
const EGG  = ["......XX......", ".....XXXX.....", "....XXXXXX....", "....XXXXXX....", "...XXXXXXXX...", "...XXXXXXXX...",
              "...XXXXXXXX...", "...XXXXXXXX...", "....XXXXXX....", ".....XXXX.....", ".............."];
const FACES = {
  happy: [[4,4],[4,5],[9,4],[9,5],[4,7],[5,8],[6,8],[7,8],[8,8],[9,7]],
  meh:   [[4,4],[4,5],[9,4],[9,5],[5,8],[6,8],[7,8],[8,8]],
  ugh:   [[3,3],[4,4],[10,3],[9,4],[4,5],[9,5],[5,7],[6,7],[7,7],[8,7],[4,8],[9,8]],
  sleep: [[3,5],[4,5],[5,5],[8,5],[9,5],[10,5],[6,8],[7,8]],
  dead:  [[3,4],[5,4],[4,5],[3,6],[5,6],[8,4],[10,4],[9,5],[8,6],[10,6],[5,8],[6,8],[7,8],[8,8]],
  egg:   [[6,3],[8,5],[5,6],[9,7]],
};
const PET_COLORS = ["#3DA5A5", "#F4A053", "#A5AF80", "#EF7364"];   // the deck's pet colours
function runs(cells) {   // merge pixels into horizontal runs -> short SVG path
  const rows = {}; cells.forEach(([x, y]) => (rows[y] ??= []).push(x));
  let d = "";
  for (const y of Object.keys(rows).map(Number).sort((a, b) => a - b)) {
    const xs = rows[y].sort((a, b) => a - b); let s = xs[0], p = xs[0];
    for (const x of [...xs.slice(1), Infinity]) { if (x === p + 1) { p = x; continue; } d += `M${s} ${y}h${p - s + 1}v1h-${p - s + 1}z`; s = p = x; }
  }
  return d;
}
const petColor = (addr) => PET_COLORS[parseInt(addr.slice(2, 10), 16) % PET_COLORS.length];
function sprite(addr, state, label) {
  const shape = state === "egg" ? EGG : BODY;
  const face = FACES[state] || FACES.happy, f = new Set(face.map(([x, y]) => x + "," + y));
  const body = []; shape.forEach((r, y) => [...r].forEach((c, x) => { if (c === "X" && !f.has(x + "," + y)) body.push([x, y]); }));
  const color = petColor(addr);
  const bodyFill = state === "dead" ? "#AEB4B5" : state === "egg" ? "#FBF6E9" : color;
  const markFill = state === "egg" ? color : "#1E2A1B";
  const viewBox = state === "egg" ? "2 0 10 11" : "0 0 14 11";
  let s = `<path fill="${bodyFill}" d="${runs(body)}"/><path fill="${markFill}" d="${runs(face)}"/>`;
  if (state === "happy") s += `<path fill="#EF7364" d="${runs([[2, 6], [11, 6]])}"/>`;
  return `<svg class="pet" viewBox="${viewBox}" shape-rendering="crispEdges" role="img" aria-label="${esc(label)}">${s}</svg>`;
}
const POOP = `<svg viewBox="0 0 5 5" shape-rendering="crispEdges" aria-hidden="true"><path fill="#86381D" d="M2 0h1v1h-1zM1 1h3v1h-3zM1 2h3v1h-3zM0 3h5v1h-5zM0 4h5v1h-5z"/></svg>`;
// The Tamagotchi shell from the cover slide (the screen and buttons are HTML on top of it)
const SHELL = `<svg class="shell" viewBox="0 0 40 46" aria-hidden="true"><path fill="#00747A" d="M20 1C30 1 39 12 39 26C39 37 31 45 20 45C9 45 1 37 1 26C1 12 10 1 20 1Z"/><path fill="none" stroke="#3DA5A5" stroke-width="1.2" d="M20 3.5C28.5 3.5 36.5 13.5 36.5 26C36.5 35.5 29.5 42.5 20 42.5C10.5 42.5 3.5 35.5 3.5 26C3.5 13.5 11.5 3.5 20 3.5Z"/><rect x="8" y="10" width="24" height="20" rx="2.5" fill="#033E3F"/></svg>`;

// ---------------------------------------------------------------- reading the chain
async function call(target, iface, fn, args = []) {
  try {
    const data = await read.call({ to: target, data: iface.encodeFunctionData(fn, args) });
    if (!data || data === "0x") return undefined;
    return iface.decodeFunctionResult(fn, data)[0];
  } catch { return undefined; }
}
const has = (p, fn) => p.code && p.code.includes(petI.getFunction(fn).selector.slice(2));

// Reads who a pet is, once. A failed read (RPC hiccup) is retried on the next refresh;
// only a contract that really has no name()/owner() is marked as "not a Tamagotchi".
async function loadIdentity(p) {
  p.tries = (p.tries || 0) + 1;
  let code;
  try { code = (await read.getCode(p.address)).toLowerCase(); } catch { return; }
  p.code = code;
  if (!has(p, "name") || !has(p, "owner")) { p.broken = true; p.loaded = true; return; }
  const fns = IDENTITY.filter((fn) => has(p, fn));
  const vals = await Promise.all(fns.map((fn) => call(p.address, petI, fn)));
  if (vals[fns.indexOf("name")] === undefined || vals[fns.indexOf("owner")] === undefined) {
    if (p.tries >= 5) { p.broken = true; p.loaded = true; }
    return;
  }
  fns.forEach((fn, i) => (p[fn] = vals[i]));
  p.broken = typeof p.name !== "string" || !p.owner;
  p.birthday = num(p.birthday);
  for (const k of IDENTITY.slice(3)) p[k] = num(p[k]);
  p.loaded = true;
}
async function loadLive(list) {
  const jobs = [];
  for (const p of list) for (const fn of LIVE) if (has(p, fn)) jobs.push([p, fn]);
  const vals = await Promise.all(jobs.map(([p, fn]) => call(p.address, petI, fn)));
  const next = new Map();
  jobs.forEach(([p, fn], i) => { (next.get(p) || next.set(p, {}).get(p))[fn] = vals[i]; });
  for (const [p, v] of next) {
    for (const k of ["hugs", "lastFed", "lastPlayed", "lastSlept", "sleepingUntil", "poops", "level"]) v[k] = num(v[k]);
    p.live = v;
    // the app animates stats every second from the timestamps; if a student changed the maths, trust the chain
    p.custom = false;
    const local = statsAt(p, now());
    const speed = { hunger: p.HUNGER_PER_MINUTE, boredom: p.BOREDOM_PER_MINUTE, tiredness: p.TIREDNESS_PER_MINUTE };
    p.custom = ["hunger", "boredom", "tiredness"].some((k) => v[k] !== undefined && local[k] !== undefined && Math.abs(Number(v[k]) - local[k]) > Math.max(4, (speed[k] || 0) + 1));
  }
}

// Same maths as the contract's _growsOverTime(), so bars move smoothly between blocks.
function grows(since, perMinute, t) { const el = t >= since ? t - since : 0; return Math.min(100, Math.floor(el / 60) * perMinute); }
function statsAt(p, t = now()) {
  const v = p.live || {};
  const s = {};
  if (p.custom) {
    for (const k of ["hunger", "boredom", "tiredness"]) if (v[k] !== undefined) s[k] = Number(v[k]);
  } else {
    if (v.lastFed !== undefined && p.HUNGER_PER_MINUTE !== undefined) s.hunger = grows(v.lastFed, p.HUNGER_PER_MINUTE, t);
    if (v.lastPlayed !== undefined && p.BOREDOM_PER_MINUTE !== undefined) s.boredom = grows(v.lastPlayed, p.BOREDOM_PER_MINUTE, t);
    if (v.lastSlept !== undefined && p.TIREDNESS_PER_MINUTE !== undefined) s.tiredness = grows(v.lastSlept, p.TIREDNESS_PER_MINUTE, t);
  }
  s.egg = s.hunger === undefined;
  s.alive = s.egg ? true : s.hunger < 100;
  s.sleeping = v.sleepingUntil !== undefined && t < v.sleepingUntil;
  const worst = Math.max(0, ...["hunger", "boredom", "tiredness"].filter((k) => s[k] !== undefined).map((k) => s[k]));
  s.state = s.egg ? "egg" : !s.alive ? "dead" : s.sleeping ? "sleep" : worst >= 80 ? "ugh" : worst >= 50 ? "meh" : "happy";
  if (!s.egg && v.lastFed !== undefined && p.HUNGER_PER_MINUTE) s.diesAt = v.lastFed + Math.ceil(100 / p.HUNGER_PER_MINUTE) * 60;
  return s;
}
const moodWord = { happy: "happy", meh: "so-so", ugh: "miserable", sleep: "asleep", dead: "dead", egg: "an egg" };

// One card per student: the newest pet each owner registered
function currentPets() {
  const byOwner = new Map();
  for (const p of pets.values()) {
    if (!p.loaded || p.broken) continue;
    const k = p.owner.toLowerCase(), prev = byOwner.get(k);
    byOwner.set(k, { pet: !prev || p.index > prev.pet.index ? p : prev.pet, n: (prev?.n || 0) + 1 });
  }
  for (const { pet, n } of byOwner.values()) pet.versions = n;
  return [...byOwner.values()].map((v) => v.pet);
}
const versionOf = (p) => [...pets.values()].filter((q) => q.loaded && !q.broken && same(q.owner, p.owner) && q.index <= p.index).length;
const petsOf = (owner) => [...pets.values()].filter((q) => q.loaded && !q.broken && same(q.owner, owner)).sort((a, b) => a.index - b.index);

// ---------------------------------------------------------------- polling
async function poll() {
  try {
    const [addrs, block, bank] = await Promise.all([call(CFG.park, parkI, "allPets"), read.getBlock("latest"), call(snackAddr, snackI, "balanceOf", [CFG.park])]);
    if (!addrs) throw new Error("allPets() failed");
    blockNumber = block.number; chainOffset = block.timestamp - Date.now() / 1000; parkBank = bank ?? parkBank;
    const fresh = [];
    addrs.forEach((a, i) => { if (!pets.has(a)) { const p = { address: a, index: i }; pets.set(a, p); fresh.push(p); } });
    await Promise.all([...pets.values()].filter((p) => !p.loaded).map(loadIdentity));
    const focus = route.name === "pet" ? pets.get(route.addr) : null;
    const liveSet = new Set(currentPets());
    if (focus && focus.loaded && !focus.broken) liveSet.add(focus);
    if (route.name === "me" && wallet.account) petsOf(wallet.account).forEach((p) => liveSet.add(p));
    await Promise.all([loadLive([...liveSet]), readEvents(block.number), loadWallet()]);
    rpcOk = true;
  } catch (e) {
    rpcOk = false; console.warn("poll failed", e);
  }
  firstLoad = false;
  update();
  setTimeout(poll, NET.pollMs);
}

async function fetchLogs(fromBlock, toBlock) {
  try { return await read.getLogs({ fromBlock, toBlock, topics: [EVENT_TOPICS] }); }
  catch {   // some public RPCs need an address list (max 10 per query)
    const list = [CFG.park, ...currentPets().map((p) => p.address)], parts = [];
    for (let i = 0; i < list.length; i += 10) parts.push(read.getLogs({ fromBlock, toBlock, address: list.slice(i, i + 10) }));
    return (await Promise.all(parts)).flat().sort((a, b) => a.blockNumber - b.blockNumber || a.index - b.index);
  }
}
async function readEvents(toBlock) {
  if (!lastBlock) lastBlock = Math.max(0, toBlock - NET.replayBlocks);
  const ours = new Set([CFG.park, ...pets.keys()].map((a) => a.toLowerCase()));
  let logs = [];
  for (let w = 0; lastBlock < toBlock && w < 6; w++) {
    const from = lastBlock + 1, to = Math.min(toBlock, from + NET.maxRange - 1);
    try { logs.push(...await fetchLogs(from, to)); } catch { break; }
    lastBlock = to;
  }
  const replay = firstLoad;
  for (const log of logs.filter((l) => ours.has(l.address.toLowerCase()))) {
    let ev; try { ev = logI.parseLog(log); } catch { continue; }
    if (!ev) continue;
    const p = pets.get(log.address);
    const pn = p?.name ? `<b>${esc(p.name)}</b>` : "a pet";
    const who = (a) => (wallet.account && same(a, wallet.account) ? "you" : p && same(a, p.owner) ? "its owner" : short(a));
    const text = {
      Born: () => `🥚 ${pn} was born!`, Fed: () => `🍙 ${pn} was fed by ${who(ev.args.by)}`,
      Played: () => `⚽ ${who(ev.args.by)} played with ${pn}`, Slept: () => `😴 ${pn} went to sleep`,
      Hugged: () => `🤗 ${pn} got a hug from ${who(ev.args.by)}`, Revived: () => `✨ ${pn} came back to life!`,
      Cleaned: () => `🧽 ${who(ev.args.by)} cleaned up after ${pn}`, LevelUp: () => `⭐ ${pn} reached level ${ev.args.level}`,
      Claimed: () => `🚰 ${who(ev.args.who)} claimed ${ev.args.amount} SNACK`,
    }[ev.name];
    if (!text) continue;
    feed.unshift({ html: text() + xlink("tx", log.transactionHash, "tx"), pet: log.address });
    if (!replay && p && FX[ev.name] && !(localFx.get(log.address + ev.name) > Date.now() - 30000)) burst(log.address, ...FX[ev.name]);
  }
  feed.splice(80);
}

// ---------------------------------------------------------------- wallet
async function loadWallet() {
  if (!wallet.account) return;
  const a = wallet.account;
  const focus = route.name === "pet" ? route.addr : null;
  const [bal, sn, wait, allow] = await Promise.all([
    read.getBalance(a).catch(() => wallet.coin), call(snackAddr, snackI, "balanceOf", [a]),
    call(CFG.park, parkI, "secondsUntilClaim", [a]), focus ? call(snackAddr, snackI, "allowance", [a, focus]) : undefined,
  ]);
  wallet.coin = bal; wallet.snack = sn ?? wallet.snack;
  if (wait !== undefined) wallet.claimAt = now() + Number(wait);
  if (focus && allow !== undefined) wallet.allowance.set(focus.toLowerCase(), allow);
}
async function connect() {
  if (!window.ethereum) { toast(`To play you need MetaMask: <a href="https://metamask.io/download/" target="_blank" rel="noopener">metamask.io</a>`, true); return false; }
  try {
    const accs = await window.ethereum.request({ method: "eth_requestAccounts" });
    wallet.account = ethers.getAddress(accs[0]);
    store.set("connected", "1");
    await ensureChain();
    await loadWallet(); update();
    return true;
  } catch (e) { toast(friendly(e), true); return false; }
}
async function ensureChain() {
  const hex = "0x" + NET.chainId.toString(16);
  let cid = await window.ethereum.request({ method: "eth_chainId" });
  if (parseInt(cid, 16) !== NET.chainId) {
    try { await window.ethereum.request({ method: "wallet_switchEthereumChain", params: [{ chainId: hex }] }); }
    catch (e) {
      if (e.code !== 4902 && e?.data?.originalError?.code !== 4902) throw e;
      await window.ethereum.request({ method: "wallet_addEthereumChain", params: [{
        chainId: hex, chainName: NET.label, rpcUrls: [CFG.rpc || NET.rpc],
        nativeCurrency: { name: NET.currency === "ETH" ? "Ether" : NET.currency, symbol: NET.currency, decimals: 18 },
        blockExplorerUrls: NET.explorer ? [NET.explorer] : [] }] });
    }
    cid = await window.ethereum.request({ method: "eth_chainId" });
  }
  wallet.chainOk = parseInt(cid, 16) === NET.chainId;
  return wallet.chainOk;
}
if (window.ethereum) {
  window.ethereum.on?.("accountsChanged", (a) => { wallet.account = a[0] ? ethers.getAddress(a[0]) : null; wallet.allowance.clear(); loadWallet().then(update); });
  window.ethereum.on?.("chainChanged", (c) => { wallet.chainOk = parseInt(c, 16) === NET.chainId; update(); });
}

// Revert reasons -> what the pet "says"
function friendly(e) {
  const raw = [e?.reason, e?.revert?.args?.[0], e?.info?.error?.message, e?.error?.message, e?.shortMessage, e?.message].find((x) => typeof x === "string" && x) || "Something went wrong";
  if (e?.code === "ACTION_REJECTED" || e?.code === 4001 || /user (rejected|denied)/i.test(raw)) return "You cancelled it in MetaMask.";
  if (/insufficient funds/i.test(raw)) return `Not enough ${NET.currency} for gas. Ask your teacher for a top-up.`;
  const m = raw.match(/reverted(?: with reason string)?:?\s*["']?([^"'\n]+)["']?/i) || raw.match(/reason="([^"]+)"/);
  return (m ? m[1] : raw).replace(/^execution reverted:?\s*/i, "").trim();
}

// Sends one transaction: checks it first (free), then asks MetaMask, then waits for the block.
async function send({ to, iface, fn, args = [], label, petAddr, fx, event }) {
  if (wallet.busy) return;
  if (!wallet.account && !(await connect())) return;
  if (!(await ensureChain().catch(() => false))) { toast(`Switch MetaMask to ${NET.label} first.`, true); return; }
  const data = iface.encodeFunctionData(fn, args);
  let gas;
  try { gas = await read.estimateGas({ from: wallet.account, to, data }); }
  catch (e) { say(petAddr, friendly(e), true); return; }   // would fail: say why, spend nothing
  wallet.busy = true; update();
  try {
    const signer = await new ethers.BrowserProvider(window.ethereum).getSigner(wallet.account);
    const tx = await signer.sendTransaction({ to, data, gasLimit: (gas * 130n) / 100n });   // +30%: estimates can be a hair low
    toast(`⏳ <code>${esc(label)}</code> sent… ${xlink("tx", tx.hash, "view on the explorer")}`);
    const rc = await read.waitForTransaction(tx.hash, 1, 180000);
    if (rc && rc.status === 1) {
      toast(`✅ <code>${esc(label)}</code> confirmed in block ${rc.blockNumber.toLocaleString()} ${xlink("tx", tx.hash, "tx")}`);
      if (fx && petAddr) { burst(petAddr, ...fx); if (event) localFx.set(petAddr + event, Date.now()); }
    } else {
      toast(`❌ <code>${esc(label)}</code> failed on-chain. ${xlink("tx", tx.hash, "See why")}`, true);
    }
  } catch (e) { say(petAddr, friendly(e), true); }
  finally { wallet.busy = false; await refreshSoon(); }
}
async function refreshSoon() { try { const list = [...new Set([...currentPets(), ...(route.addr && pets.get(route.addr) ? [pets.get(route.addr)] : [])])]; await Promise.all([loadLive(list), loadWallet()]); } catch {} update(); }

// ---------------------------------------------------------------- feedback: toasts, speech bubbles, effects
function toast(html, bad = false) {
  const t = document.createElement("div"); t.className = "toast" + (bad ? " bad" : ""); t.innerHTML = html;
  $("#toasts").append(t); setTimeout(() => t.remove(), bad ? 9000 : 7000);
}
function say(petAddr, text, bad = false) {
  const wrap = petAddr && document.querySelector(`.device-wrap[data-pet="${petAddr}"]`);
  if (!wrap) { toast(esc(text), bad); return; }
  wrap.querySelector(".bubble")?.remove();
  const b = document.createElement("div"); b.className = "bubble" + (bad ? " bad" : ""); b.textContent = text;
  wrap.append(b); setTimeout(() => b.remove(), 6500);
}
function burst(petAddr, emoji, kind) {
  document.querySelectorAll(`[data-screen="${petAddr}"]`).forEach((el) => {
    const s = document.createElement("span"); s.className = `fx ${kind}`; s.textContent = emoji;
    el.append(s); setTimeout(() => s.remove(), 1700);
  });
  document.querySelectorAll(`.card[data-pet="${petAddr}"]`).forEach((c) => { c.classList.add("flash"); setTimeout(() => c.classList.remove("flash"), 1200); });
}

// ---------------------------------------------------------------- views
function screenHTML(p, s, big) {
  const extras = `${s.sleeping ? '<span class="zzz">z Z</span>' : ""}${p.live?.level ? `<span class="lvl">LV ${p.live.level}</span>` : ""}${p.live?.poops ? `<span class="poops">${POOP.repeat(Math.min(5, p.live.poops))}</span>` : ""}`;
  return `${sprite(p.address, s.state, `${p.name} is ${moodWord[s.state]}`)}${big ? "" : `<span class="ver">v${versionOf(p)}</span>`}${extras}`;
}
const screenKey = (p, s) => [s.state, s.sleeping, p.live?.level, p.live?.poops, versionOf(p)].join("|");
function bar(label, v, key) {
  return `<div class="bar"><span>${label}</span><div class="track"><div class="fill" data-fill="${key}"></div></div><b data-num="${key}">${v ?? ""}</b></div>`;
}
function alarm(p, s) {
  if (s.egg) return { text: "Still an egg: it hatches when it learns to eat (step 2)", bad: false };
  if (!s.alive) return { text: "Starved 💀 Its owner can revive() it", bad: true };
  if (s.sleeping) return { text: `Napping · wakes up in ${dur(p.live.sleepingUntil - now())}`, bad: false };
  if (s.diesAt) { const left = s.diesAt - now(); return { text: `Starves in ${dur(left)} without food`, bad: left < 600 }; }
  return { text: "", bad: false };
}

function cardHTML(p) {
  return `<a class="card" href="#/pet/${p.address}" data-pet="${p.address}">
    <div class="lcd" data-screen="${p.address}"></div>
    <div class="name"><span>${esc(p.name)}</span><span data-mood></span></div>
    <div class="meta" data-meta></div>
    <div class="bars" data-bars></div>
    <div class="alarm" data-alarm></div>
  </a>`;
}
function updateCard(el, p) {
  const s = statsAt(p);
  const scr = el.querySelector("[data-screen]");
  const key = screenKey(p, s);
  if (scr.dataset.key !== key) { scr.dataset.key = key; scr.className = `lcd ${s.state}`; scr.innerHTML = screenHTML(p, s); }
  el.classList.toggle("mine", same(p.owner, wallet.account));
  el.querySelector("[data-mood]").textContent = p.live?.mood || "";
  el.querySelector("[data-meta]").textContent = `${ageText(p)} · ${p.live?.hugs ?? 0} hugs · ${same(p.owner, wallet.account) ? "yours" : "owner " + short(p.owner)}`;
  const bars = el.querySelector("[data-bars]");
  const want = ["hunger", "boredom", "tiredness"].filter((k) => s[k] !== undefined).join(",");
  if (bars.dataset.keys !== want) {
    bars.dataset.keys = want;
    bars.innerHTML = want ? want.split(",").map((k) => bar(k[0].toUpperCase() + k.slice(1), s[k], k)).join("") : "";
  }
  liveBars(el, s);
  const a = alarm(p, s), al = el.querySelector("[data-alarm]");
  al.textContent = a.text; al.classList.toggle("bad", a.bad);
}
function liveBars(root, s) {
  for (const k of ["hunger", "boredom", "tiredness"]) {
    const f = root.querySelector(`[data-fill="${k}"]`), n = root.querySelector(`[data-num="${k}"]`);
    if (!f || s[k] === undefined) continue;
    f.style.width = s[k] + "%"; f.className = "fill" + (s[k] >= 80 ? " high" : s[k] >= 50 ? " mid" : "");
    if (n) n.textContent = s[k];
  }
}

function viewPark() {
  $("#view").innerHTML = `
    <div class="park-head">
      <div>
        <p class="eyebrow">Live on ${esc(NET.label)}</p>
        <h1>The Pet Park</h1>
        <p class="join">Join at <b>${esc(location.host + location.pathname)}</b> · Pet Park address <code>${esc(CFG.park)}</code></p>
      </div>
      <div class="kpis">
        <div class="kpi"><b data-k="alive">–</b><span>pets alive</span></div>
        <div class="kpi"><b data-k="hugs">–</b><span>hugs</span></div>
        <div class="kpi"><b data-k="bank">–</b><span>SNACK in the park</span></div>
        <div class="kpi"><b data-k="block">–</b><span>block</span></div>
      </div>
    </div>
    <div class="park">
      <div>
        <div class="grid" id="cards"></div>
        <div class="graveyard" id="gy" hidden><p class="eyebrow">Graveyard</p><div class="grid" id="tombs"></div></div>
      </div>
      <aside class="side">
        <section class="panel"><p class="eyebrow">Most hugged</p><ol class="top" id="top-hugs"></ol></section>
        <section class="panel"><p class="eyebrow">Oldest alive</p><ol class="top" id="top-age"></ol></section>
        <section class="panel"><p class="eyebrow">Live activity</p><ul class="feed" id="feed"></ul></section>
      </aside>
    </div>`;
}
function updatePark() {
  const list = currentPets().filter((p) => p.live);
  const withStats = list.map((p) => [p, statsAt(p)]);
  const alive = withStats.filter(([, s]) => s.alive).map(([p]) => p).sort((a, b) => a.birthday - b.birthday);
  const dead = withStats.filter(([, s]) => !s.alive).map(([p]) => p);
  const kp = (k, v) => { const el = document.querySelector(`[data-k="${k}"]`); if (el) el.textContent = v; };
  kp("alive", `${alive.length}/${list.length}`);
  kp("hugs", list.reduce((n, p) => n + (p.live.hugs || 0), 0));
  kp("bank", Number(parkBank).toLocaleString());
  kp("block", blockNumber.toLocaleString());

  const cards = $("#cards");
  if (!alive.length) cards.innerHTML = `<div class="empty">No pets yet. Deploy your Tamagotchi in Remix with the Pet Park address <code>${esc(CFG.park)}</code>.</div>`;
  else {
    cards.querySelector(".empty")?.remove();
    const want = alive.map((p) => p.address);
    [...cards.children].forEach((c) => { if (!want.includes(c.dataset.pet)) c.remove(); });
    want.forEach((a, i) => {
      let el = cards.querySelector(`[data-pet="${a}"]`);
      if (!el) { const t = document.createElement("template"); t.innerHTML = cardHTML(pets.get(a)).trim(); el = t.content.firstChild; }
      if (cards.children[i] !== el) cards.insertBefore(el, cards.children[i] || null);
      updateCard(el, pets.get(a));
    });
  }
  $("#gy").hidden = !dead.length;
  $("#tombs").innerHTML = dead.map((p) => `<a class="tomb" href="#/pet/${p.address}">${sprite(p.address, "dead", `${p.name} died`)}<b>${esc(p.name)}</b>${ageText(p).replace(" old", "")} · ${p.live.hugs || 0} hugs</a>`).join("");
  $("#top-hugs").innerHTML = [...list].sort((a, b) => (b.live.hugs || 0) - (a.live.hugs || 0)).slice(0, 5).map((p) => `<li>${esc(p.name)} — ${p.live.hugs || 0}</li>`).join("") || "<li>–</li>";
  $("#top-age").innerHTML = alive.slice(0, 5).map((p) => `<li>${esc(p.name)} — ${ageText(p).replace(" old", "")}</li>`).join("") || "<li>–</li>";
  $("#feed").innerHTML = feed.map((f) => `<li>${f.html}</li>`).join("") || "<li class='muted'>Waiting for the first transaction…</li>";
}

function viewPet(addr) {
  const p = pets.get(addr);
  if (!p || !p.loaded) { $("#view").innerHTML = `<p class="muted">Looking for this pet on the blockchain…</p>`; return; }
  if (p.broken) { $("#view").innerHTML = `<p>That address isn't a Tamagotchi. <a href="#/">Back to the park</a></p>`; return; }
  $("#view").innerHTML = `
    <a class="back" href="#/">← The park</a>
    <div class="petpage">
      <div>
        <div class="device-wrap" data-pet="${p.address}">
          <div class="device">
            ${SHELL}
            <div class="screen" data-screen="${p.address}"></div>
            <button class="dbtn a" type="button" data-do="feed" aria-label="Feed"></button>
            <button class="dbtn b" type="button" data-do="play" aria-label="Play"></button>
            <button class="dbtn c" type="button" data-do="hug" aria-label="Hug"></button>
          </div>
        </div>
        <div class="dlabels"><span>Feed<small data-cost="feed"></small></span><span>Play<small data-cost="play"></small></span><span>Hug<small>free</small></span></div>
      </div>
      <div>
        <div class="pet-title"><h1>${esc(p.name)}</h1><span class="mood" data-mood></span></div>
        <p class="meta" data-meta></p>
        <div class="stats" id="stats"></div>
        <div id="approve"></div>
        <p class="eyebrow">Things you can do</p>
        <div class="actions" id="actions"></div>
        <p class="eyebrow gap-top">This pet on the blockchain</p>
        <dl class="facts" id="facts"></dl>
        <p class="eyebrow gap-top">Versions by this owner</p>
        <div class="versions" id="versions"></div>
        <p class="eyebrow gap-top">What happened lately</p>
        <ul class="feed" id="pet-feed"></ul>
      </div>
    </div>`;
  $("#view").querySelectorAll("[data-do]").forEach((b) => b.addEventListener("click", () => act(p, b.dataset.do)));
}
function statRow(label, k, say) { return `<div class="stat"><span class="label">${label}</span><div class="track"><div class="fill" data-fill="${k}"></div></div><span class="say" data-say="${k}">${say}</span></div>`; }
function updatePet() {
  const p = pets.get(route.addr);
  if (!p?.loaded) { if (p === undefined && !firstLoad) $("#view").innerHTML = `<p>No pet at that address in this park. <a href="#/">Back to the park</a></p>`; return; }
  if (!document.querySelector(`.device-wrap[data-pet="${p.address}"]`)) viewPet(p.address);
  if (!p.live) return;
  const s = statsAt(p), v = p.live, mine = same(p.owner, wallet.account);
  const scr = document.querySelector(`.device [data-screen]`);
  const key = screenKey(p, s);
  if (scr.dataset.key !== key) { scr.dataset.key = key; scr.className = `screen lcd ${s.state}`; scr.innerHTML = screenHTML(p, s, true); }
  $("[data-mood]").textContent = v.mood || "";
  $("[data-meta]").textContent = `v${versionOf(p)} · ${ageText(p)} · ${v.hugs ?? 0} hugs · ${mine ? "this is your pet" : "owner " + short(p.owner)}${v.level !== undefined ? ` · level ${v.level}` : ""}`;

  // stats in plain words
  const st = $("#stats"); const keys = ["hunger", "boredom", "tiredness"].filter((k) => s[k] !== undefined).join(",");
  if (st.dataset.keys !== keys) { st.dataset.keys = keys; st.innerHTML = keys ? keys.split(",").map((k) => statRow(k[0].toUpperCase() + k.slice(1), k, "")).join("") : `<p class="muted">An egg has no stats yet. Teach it to eat in step 2 and it hatches.</p>`; }
  liveBars(st, s);
  const sayText = {
    hunger: () => !s.alive ? ["Starved. Its owner can call revive()", true] : s.hunger === 0 ? ["Full", false] : [`Starves in ${dur(s.diesAt - now())} · +${p.HUNGER_PER_MINUTE}/min`, s.diesAt - now() < 600],
    boredom: () => s.boredom >= 80 ? ["Bored stiff!", true] : s.boredom >= 50 ? [`Getting bored · +${p.BOREDOM_PER_MINUTE}/min`, false] : [`Having fun · +${p.BOREDOM_PER_MINUTE}/min`, false],
    tiredness: () => s.sleeping ? [`Napping · wakes up in ${dur(v.sleepingUntil - now())}`, false] : s.tiredness >= 80 ? ["Too tired to play: its owner can sleep()", true] : [`Can play until 80 · +${p.TIREDNESS_PER_MINUTE}/min`, false],
  };
  for (const k of ["hunger", "boredom", "tiredness"]) { const el = st.querySelector(`[data-say="${k}"]`); if (el && s[k] !== undefined) { const [t, bad] = sayText[k](); el.textContent = t; el.classList.toggle("bad", bad); } }

  // the approve step, made visible
  const costs = ["FEED_COST", "PLAY_COST", ...(mine && !s.alive ? ["REVIVE_COST"] : [])].map((k) => p[k]).filter((x) => x !== undefined);
  const need = costs.length ? Math.max(...costs) : 0;
  const allow = wallet.allowance.get(p.address.toLowerCase());
  const ap = $("#approve");
  if (!need || !wallet.account) ap.innerHTML = need && !wallet.account ? `<div class="approve"><p>Connect your wallet to feed and play with ${esc(p.name)}.</p><button class="btn" type="button" data-connect>Connect wallet</button></div>` : "";
  else if (allow !== undefined && allow < BigInt(need)) ap.innerHTML = `<div class="approve"><p><b>First, allow ${esc(p.name)} to take your SNACK.</b> This is <code>approve(pet, 200)</code> on the SNACK token: a spending limit, like a gift card. Allowed now: ${allow}.</p><button class="btn warm" type="button" data-approve ${wallet.busy ? "disabled" : ""}>Allow 200 SNACK</button></div>`;
  else ap.innerHTML = allow !== undefined ? `<p class="muted">${esc(p.name)} may spend ${allow} more of your SNACK (your allowance).</p>` : "";
  ap.querySelector("[data-approve]")?.addEventListener("click", () => send({ to: snackAddr, iface: snackI, fn: "approve", args: [p.address, 200], label: "approve(pet, 200)", petAddr: p.address }));
  ap.querySelector("[data-connect]")?.addEventListener("click", connect);

  // actions (device buttons + the full list)
  const avail = ACTIONS.filter((a) => has(p, a.fn));
  const acts = $("#actions"); const ak = avail.map((a) => a.fn).join(",") + "|" + wallet.busy;
  if (acts.dataset.k !== ak) {
    acts.dataset.k = ak;
    acts.innerHTML = avail.map((a) => `<button class="action" type="button" data-do="${a.fn}" ${wallet.busy ? "disabled" : ""}><b>${a.fx} ${a.label}</b><small><code>${a.fn}()</code> · ${a.cost && p[a.cost] !== undefined ? p[a.cost] + " SNACK" : "free"} · ${a.owner ? "owner only" : "anyone"}</small><br><small>${a.does}</small></button>`).join("") || `<p class="muted">This version has no actions yet.</p>`;
    acts.querySelectorAll("[data-do]").forEach((b) => b.addEventListener("click", () => act(p, b.dataset.do)));
  }
  for (const a of ACTIONS.slice(0, 3)) {
    const b = document.querySelector(`.dbtn[data-do="${a.fn}"]`); if (!b) continue;
    b.disabled = !has(p, a.fn) || wallet.busy; b.title = has(p, a.fn) ? `${a.fn}()` : "This version can't do that yet";
    const c = document.querySelector(`[data-cost="${a.fn}"]`); if (c) c.textContent = has(p, a.fn) ? `${p[a.cost] ?? "?"} SNACK` : "not yet";
  }

  $("#facts").innerHTML = `
    <dt>Address</dt><dd><code>${p.address}</code> ${xlink("address", p.address, "explorer")}</dd>
    <dt>Owner</dt><dd><code>${short(p.owner)}</code>${mine ? " (you)" : ""} ${xlink("address", p.owner, "explorer")}</dd>
    <dt>Born</dt><dd>${new Date(p.birthday * 1000).toLocaleString()}</dd>
    ${v.bestFriend && v.bestFriend !== ethers.ZeroAddress ? `<dt>Best friend</dt><dd><code>${short(v.bestFriend)}</code></dd>` : ""}
    <dt>In Remix</dt><dd>Contract <b>Tamagotchi</b> → <b>At Address</b> → paste the address above</dd>`;
  const vs = petsOf(p.owner);
  $("#versions").innerHTML = vs.map((q, i) => `<a class="chip ${q === p ? "on" : ""}" href="#/pet/${q.address}">v${i + 1} · ${esc(q.name)}</a>`).join("");
  $("#pet-feed").innerHTML = feed.filter((f) => same(f.pet, p.address)).slice(0, 12).map((f) => `<li>${f.html}</li>`).join("") || "<li class='muted'>Nothing yet.</li>";
}

async function act(p, fn) {
  const a = ACTIONS.find((x) => x.fn === fn); if (!a || !has(p, fn)) return;
  if (!wallet.account && !(await connect())) return;
  const cost = a.cost ? p[a.cost] : 0;
  if (cost) {
    if (wallet.snack < BigInt(cost)) { say(p.address, `I cost ${cost} SNACK and you have ${wallet.snack}. Claim some from the faucet (top bar).`, true); return; }
    const allow = wallet.allowance.get(p.address.toLowerCase()) ?? (await call(snackAddr, snackI, "allowance", [wallet.account, p.address]));
    if (allow !== undefined && allow < BigInt(cost)) { say(p.address, "I can't take your SNACK yet. Click “Allow 200 SNACK” first: that's approve().", true); return; }
  }
  const event = { feed: "Fed", play: "Played", hug: "Hugged", sleep: "Slept", revive: "Revived", clean: "Cleaned" }[fn];
  send({ to: p.address, iface: petI, fn, label: `${fn}()`, petAddr: p.address, fx: [a.fx, a.fxKind], event });
}

function viewMe() {
  if (!wallet.account) {
    $("#view").innerHTML = `<div class="setup panel"><h2>My pets</h2><p>Connect your wallet to see the pets you deployed.</p><button class="btn" type="button" id="me-connect">Connect wallet</button></div>`;
    $("#me-connect").addEventListener("click", connect); return;
  }
  const mine = petsOf(wallet.account);
  $("#view").innerHTML = `<p class="eyebrow">Your wallet ${short(wallet.account)}</p><h1 class="gap-bottom">My pets</h1>
    ${mine.length ? `<div class="grid" id="cards"></div>` : `<div class="empty">You haven't deployed a pet yet. In Remix: contract <b>Tamagotchi</b> → Deploy with your pet's name and the Pet Park address <code>${esc(CFG.park)}</code>.</div>`}`;
  const cards = $("#cards"); if (!cards) return;
  cards.innerHTML = mine.map(cardHTML).join("");
}
function updateMe() {
  const cards = $("#cards"); if (!cards || !wallet.account) return;
  const mine = petsOf(wallet.account);
  if (cards.children.length !== mine.length) cards.innerHTML = mine.map(cardHTML).join("");
  mine.forEach((p) => { const el = cards.querySelector(`[data-pet="${p.address}"]`); if (el && p.live) updateCard(el, p); });
}

function viewHow() {
  $("#view").innerHTML = `<div class="prose">
    <p class="eyebrow">How it works</p><h1>Your pet is a smart contract</h1>
    <p>Every pet here is a program you wrote and deployed on <b>${esc(NET.label)}</b>, a real public blockchain. This website doesn't store anything: it only <b>reads</b> the blockchain, and sends your clicks to MetaMask as transactions.</p>
    <h2>1. Wallet</h2>
    <ol><li>Install MetaMask and create a wallet. Write the secret phrase on paper. Never type it anywhere else.</li>
    <li>Click <b>Connect wallet</b> at the top: the site adds ${esc(NET.label)} to MetaMask for you.</li>
    <li>Your teacher sends you a little ${esc(NET.currency)} for gas.</li></ol>
    <h2>2. SNACK</h2><p>Click <b>Claim SNACK</b> at the top: that calls <code>claim()</code> on the Pet Park (50 SNACK, every 3 minutes). SNACK is a play token: it only feeds pets.</p>
    <h2>3. Your pet</h2><p>Write it in <b>Remix</b> (remix.ethereum.org) and deploy it with the Pet Park address <code>${esc(CFG.park)}</code>. It appears in the park within a few seconds.</p>
    <h2>4. Taking care</h2><ul>
    <li><b>Feed</b> (<code>feed()</code>) and <b>Play</b> (<code>play()</code>) cost SNACK. First click <b>Allow 200 SNACK</b>: that's <code>approve()</code>, a spending limit for that one pet. Every new version needs a new approve.</li>
    <li><b>Hug</b> is free. Anyone can hug, feed or play with any pet.</li>
    <li><b>Put to bed</b> and <b>Revive</b> are owner-only. Try them on a friend's pet and read what it says.</li>
    <li>Hunger grows every minute. At 100 the pet dies.</li></ul>
    <h2>5. See it for yourself</h2><p>Every action has a link to the block explorer${NET.explorer ? ` (<a href="${NET.explorer}" target="_blank" rel="noopener">${esc(NET.explorer.replace("https://", ""))}</a>)` : ""}: that's the blockchain itself, no website in between.</p>
    <p class="muted">Pet Park address: <code>${esc(CFG.park)}</code> ${xlink("address", CFG.park, "explorer")} · SNACK token: <code>${esc(snackAddr || "")}</code></p>
  </div>`;
}

function viewSetup(error) {
  const opts = Object.entries(NETWORKS).map(([k, n]) => `<option value="${k}" ${k === CFG.network ? "selected" : ""}>${n.label}</option>`).join("");
  $("#view").innerHTML = `<div class="setup panel"><h2>Set up the Pet Park</h2>
    <p class="muted">Tip for the teacher: put these in <code>config.js</code> so students never see this screen.</p>
    <label class="eyebrow" for="s-net">Network</label><select id="s-net">${opts}</select>
    <label class="eyebrow" for="s-park">Pet Park address</label><input id="s-park" value="${esc(CFG.park)}" placeholder="0x…">
    ${error ? `<p class="bad">${esc(error)}</p>` : ""}
    <button class="btn" type="button" id="s-go">Open the park</button></div>`;
  $("#s-go").addEventListener("click", () => {
    store.set("network", $("#s-net").value); store.set("park", $("#s-park").value.trim());
    location.search = `?network=${encodeURIComponent($("#s-net").value)}&park=${encodeURIComponent($("#s-park").value.trim())}`;
  });
}

// ---------------------------------------------------------------- wallet bar, footer
function updateWallet() {
  const w = $("#wallet");
  if (!window.ethereum) { w.innerHTML = `<a class="chip" href="https://metamask.io/download/" target="_blank" rel="noopener">Install MetaMask to play</a>`; return; }
  if (!wallet.account) { if (!w.querySelector("#btn-connect")) { w.innerHTML = `<button class="btn" type="button" id="btn-connect">Connect wallet</button>`; $("#btn-connect").addEventListener("click", connect); } return; }
  if (!wallet.chainOk) { w.innerHTML = `<button class="btn warm" type="button" id="btn-switch">Switch to ${esc(NET.label)}</button>`; $("#btn-switch").addEventListener("click", () => ensureChain().then(loadWallet).then(update).catch((e) => toast(friendly(e), true))); return; }
  const wait = Math.max(0, wallet.claimAt - now());
  const html = `<span class="chip" title="${wallet.account}">${short(wallet.account)}</span>
    <span class="chip">${coin(wallet.coin)} ${esc(NET.currency)}</span>
    <span class="chip">${wallet.snack} SNACK</span>
    <button class="btn warm" type="button" id="btn-claim" ${wait > 0 || wallet.busy ? "disabled" : ""}>${wait > 0 ? `Claim in ${dur(wait)}` : "Claim SNACK"}</button>`;
  if (w.dataset.html !== html) { w.dataset.html = html; w.innerHTML = html; $("#btn-claim").addEventListener("click", () => send({ to: CFG.park, iface: parkI, fn: "claim", label: "claim()" })); }
}
function updateFoot() {
  $("#foot-status").innerHTML = rpcOk ? `Reading ${esc(NET.label)} · block ${blockNumber.toLocaleString()} · Pet Park ${xlink("address", CFG.park, short(CFG.park)) || short(CFG.park)}` : `<span class="bad">The blockchain isn't answering, retrying…</span>`;
}

// ---------------------------------------------------------------- router + render loop
function parseRoute() {
  const h = location.hash.replace(/^#\/?/, "");
  if (h.startsWith("pet/")) { const a = h.slice(4); return ethers.isAddress(a) ? { name: "pet", addr: ethers.getAddress(a) } : { name: "park" }; }
  if (h === "me") return { name: "me" };
  if (h === "how") return { name: "how" };
  return { name: "park" };
}
function show() {
  route = parseRoute();
  document.querySelectorAll(".tabs a").forEach((a) => a.classList.toggle("on", a.dataset.route === route.name));
  ({ park: viewPark, pet: () => viewPet(route.addr), me: viewMe, how: viewHow })[route.name]();
  update();
  if (route.name === "pet" || route.name === "me") refreshSoon();
}
function update() {
  updateWallet(); updateFoot();
  if (route.name === "park" && $("#cards")) updatePark();
  if (route.name === "pet") updatePet();
  if (route.name === "me") updateMe();
}

// ---------------------------------------------------------------- start
async function start() {
  $("#net-badge").textContent = NET ? NET.label : "?";
  try { if (store.get("theme")) document.documentElement.dataset.theme = store.get("theme"); } catch {}
  if (params.has("screen")) document.body.classList.add("screen");
  $("#btn-theme").addEventListener("click", () => { const t = document.documentElement.dataset.theme === "dark" ? "light" : "dark"; document.documentElement.dataset.theme = t; store.set("theme", t); });
  $("#btn-screen").addEventListener("click", () => document.body.classList.toggle("screen"));
  if (!NET) return viewSetup(`Unknown network "${CFG.network}"`);
  if (!ethers.isAddress(CFG.park)) return viewSetup();
  CFG.park = ethers.getAddress(CFG.park);
  // batchMaxCount 10: public RPCs cap JSON-RPC batches (mainnet.optimism.io rejects more than 10 with HTTP 413)
  read = new ethers.JsonRpcProvider(CFG.rpc || NET.rpc, NET.chainId, { staticNetwork: true, batchMaxCount: 10 });
  try {
    if ((await read.getCode(CFG.park)) === "0x") return viewSetup(`There's no contract at that address on ${NET.label}.`);
    snackAddr = await call(CFG.park, parkI, "snack");
    if (!snackAddr) return viewSetup("That contract doesn't look like a Pet Park.");
  } catch (e) { return viewSetup(`Can't reach ${NET.label}: ${e.shortMessage || e.message}`); }
  window.addEventListener("hashchange", show);
  // reconnect silently if the student connected before
  if (window.ethereum && store.get("connected")) {
    try { const accs = await window.ethereum.request({ method: "eth_accounts" }); if (accs[0]) { wallet.account = ethers.getAddress(accs[0]); wallet.chainOk = parseInt(await window.ethereum.request({ method: "eth_chainId" }), 16) === NET.chainId; } } catch {}
  }
  show();
  poll();
  setInterval(() => { if (!document.hidden) { updateWallet(); if (route.name === "park" && $("#cards")) updatePark(); else if (route.name === "pet") updatePet(); else if (route.name === "me") updateMe(); } }, 1000);
}
start();
