// qalbee/ui.jsx — Qalbee core components (countdown, prayer table, tracker, heatmap, compass, tasbih, nav)
/* global React, QIcon, QalbMark, MotifBg, bnD, Card, Chip */

/* ---------- smart countdown card ---------- */
/* state: calm | amber | urgent | sahri | iftar */
const CD_STATES = {
  calm:   { bg: "var(--surface)",      fg: "var(--ink)",          sub: "var(--ink-2)",        bar: "var(--primary)", ring: "var(--line)" },
  amber:  { bg: "var(--warn-soft)",    fg: "var(--warn)",         sub: "var(--warn)",         bar: "var(--warn)",    ring: "transparent" },
  urgent: { bg: "var(--urgent-soft)",  fg: "var(--urgent)",       sub: "var(--urgent)",       bar: "var(--urgent)",  ring: "transparent" },
  sahri:  { bg: "var(--primary)",      fg: "var(--on-primary)",   sub: "var(--on-primary)",   bar: "var(--accent)",  ring: "transparent" },
  iftar:  { bg: "var(--accent-soft)",  fg: "var(--on-accent-soft)", sub: "var(--on-accent-soft)", bar: "var(--accent)", ring: "transparent" },
};
const CountdownCard = ({ state = "calm", eyebrow, big, sub, pct = 0.42, digits, size = 56, style }) => {
  const c = CD_STATES[state];
  const fmt = digits || ((x) => x);
  return (
    <div style={{ background: c.bg, borderRadius: "var(--r-xl)", padding: "22px 24px 20px", position: "relative",
      overflow: "hidden", boxShadow: "var(--e-1)", border: `1px solid ${c.ring}`, ...style }}>
      <MotifBg opacity={0.055} cell={120} style={{ color: c.fg }}></MotifBg>
      <div style={{ position: "relative" }}>
        <div className="t-overline" style={{ color: c.sub, opacity: 0.85 }}>{eyebrow}</div>
        <div className="t-num" style={{ fontSize: size, fontWeight: 700, letterSpacing: "-1.5px", lineHeight: 1.05, margin: size > 44 ? "8px 0 6px" : "5px 0 4px", color: c.fg }}>{fmt(big)}</div>
        <div className="t-caption" style={{ color: c.sub, opacity: 0.85, fontSize: 12.5 }}>{sub}</div>
        <div style={{ height: 5, borderRadius: 3, background: "color-mix(in oklab, currentColor 14%, transparent)", marginTop: size > 44 ? 16 : 10, color: c.fg }}>
          <div style={{ width: `${pct * 100}%`, height: "100%", borderRadius: 3, background: c.bar }}></div>
        </div>
      </div>
    </div>
  );
};

/* ---------- prayer table ---------- */
const PrayerTable = ({ rows, activeIdx, digits, dir, labels = {}, dense, style }) => {
  const fmt = digits || ((x) => x);
  const L = { jamaat: "Jamaat", track: "", set: "Set jamaat", ...labels };
  return (
    <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)",
      boxShadow: "var(--e-1)", overflow: "hidden", ...style }}>
      {rows.map((r, i) => {
        const active = i === activeIdx;
        return (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: dense ? "0 12px" : "0 16px", minHeight: r.sunrise ? (dense ? 30 : 42) : (dense ? 40 : 54),
            background: active ? "var(--primary-soft)" : "transparent",
            borderTop: i ? "1px solid var(--line)" : "none", opacity: r.sunrise ? 0.85 : 1 }}>
            <span style={{ width: 8, height: 8, borderRadius: 99, flexShrink: 0,
              background: active ? "var(--primary)" : r.done ? "var(--ok)" : "var(--line)" }}></span>
            <span className={r.sunrise ? "t-caption c-2" : "t-title-sm"} style={{ width: dense ? 64 : 84, fontSize: dense && !r.sunrise ? 13.5 : undefined, fontWeight: active ? 700 : undefined,
              color: active ? "var(--on-primary-soft)" : undefined }}>{r.name}</span>
            <span className="t-caption t-num c-2" style={{ flex: 1, fontSize: dense ? 11 : 12.5, whiteSpace: dense ? "nowrap" : undefined, color: active ? "var(--on-primary-soft)" : undefined }}>
              {fmt(r.time)}
            </span>
            {!r.sunrise && (r.jamaat
              ? <span className="t-caption t-num" style={{ width: dense ? 40 : 52, textAlign: "center", color: active ? "var(--on-primary-soft)" : "var(--ink-2)", fontWeight: 600 }}>{fmt(r.jamaat)}</span>
              : <span className="t-caption" style={{ width: dense ? 40 : 52, textAlign: "center", color: "var(--ink-3)", fontSize: 10.5, textDecoration: "underline", textUnderlineOffset: 2 }}>{L.set}</span>)}
            {!r.sunrise && (
              <span style={{ width: 26, height: 26, borderRadius: 99, flexShrink: 0, display: "grid", placeItems: "center",
                background: r.done ? "var(--ok)" : "transparent",
                border: r.done ? "none" : "1.8px solid var(--ink-3)",
                color: r.done ? (document.body ? "var(--ok-soft)" : "#fff") : "transparent" }}>
                {r.done && <QIcon name="check" size={14} sw={3} color="var(--bg)"></QIcon>}
              </span>
            )}
          </div>
        );
      })}
    </div>
  );
};

/* ---------- muhasaba tracker items (3 input types) ---------- */
const TrackerShell = ({ icon, tone, label, sub, trail, state, style }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 13, padding: "12px 14px", borderRadius: "var(--r-md)",
    background: "var(--surface)", border: "1px solid var(--line)", boxShadow: "var(--e-1)",
    opacity: state === "disabled" ? 0.45 : 1,
    outline: state === "focused" ? "2.5px solid var(--primary)" : "none", outlineOffset: 2,
    transform: state === "pressed" ? "scale(.98)" : "none",
    filter: state === "pressed" ? "brightness(.96)" : "none", ...style }}>
    <span style={{ width: 40, height: 40, borderRadius: 13, flexShrink: 0, display: "grid", placeItems: "center",
      background: tone || "var(--primary-soft)", color: "var(--on-primary-soft)" }}>
      <QIcon name={icon} size={20}></QIcon>
    </span>
    <span style={{ flex: 1, minWidth: 0 }}>
      <span className="t-title-sm" style={{ display: "block", fontSize: 15.5 }}>{label}</span>
      {sub && <span className="t-caption c-2" style={{ display: "block", marginTop: 1 }}>{sub}</span>}
    </span>
    {trail}
  </div>
);

const TrackerToggle = (p) => <TrackerShell {...p} trail={<window.Toggle on={p.on}></window.Toggle>}></TrackerShell>;
const TrackerCount = (p) => <TrackerShell {...p} trail={<window.Stepper val={p.val}></window.Stepper>}></TrackerShell>;
const TrackerDuration = (p) => (
  <TrackerShell {...p} trail={
    <span style={{ display: "inline-flex", alignItems: "center", gap: 7, height: 40, padding: "0 14px", borderRadius: 99,
      background: p.val ? "var(--primary-soft)" : "var(--surface-2)", color: p.val ? "var(--on-primary-soft)" : "var(--ink-3)" }}>
      <QIcon name="clock" size={15}></QIcon>
      <span className="t-label t-num">{p.val || p.placeholder || "0 min"}</span>
    </span>
  }></TrackerShell>
);

/* ---------- heatmap (GitHub style) ---------- */
const HM_LEVELS = ["var(--surface-2)",
  "color-mix(in oklab, var(--primary) 25%, var(--surface-2))",
  "color-mix(in oklab, var(--primary) 50%, var(--surface-2))",
  "color-mix(in oklab, var(--primary) 75%, var(--surface-2))",
  "var(--primary)"];
const Heatmap = ({ data, cell = 13, gap = 3.5, style }) => (
  <div style={{ display: "flex", gap, ...style }}>
    {data.map((week, i) => (
      <div key={i} style={{ display: "flex", flexDirection: "column", gap }}>
        {week.map((v, j) => (
          <span key={j} style={{ width: cell, height: cell, borderRadius: 3.5,
            background: v < 0 ? "transparent" : HM_LEVELS[v] }}></span>
        ))}
      </div>
    ))}
  </div>
);

/* ---------- progress ring ---------- */
const ProgressRing = ({ pct = 0.6, size = 120, sw = 9, color = "var(--primary)", track = "var(--surface-2)", children }) => {
  const r = (size - sw) / 2, C = 2 * Math.PI * r;
  return (
    <div style={{ width: size, height: size, position: "relative", display: "grid", placeItems: "center" }}>
      <svg width={size} height={size} style={{ position: "absolute", inset: 0, transform: "rotate(-90deg)" }}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={track} strokeWidth={sw}></circle>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={sw}
          strokeLinecap="round" strokeDasharray={C} strokeDashoffset={C * (1 - pct)}></circle>
      </svg>
      <div style={{ position: "relative", textAlign: "center" }}>{children}</div>
    </div>
  );
};

/* ---------- bottom navigation ---------- */
const NAV_ITEMS = [
  { icon: "home", en: "Home", ar: "الرئيسية", bn: "হোম" },
  { icon: "book", en: "Quran", ar: "القرآن", bn: "কুরআন" },
  { icon: "heart", en: "Muhasaba", ar: "محاسبة", bn: "মুহাসাবা" },
  { icon: "beads", en: "Dua", ar: "الأدعية", bn: "দুআ" },
  { icon: "dots", en: "More", ar: "المزيد", bn: "আরও" },
];
const BottomNav = ({ active = 0, lang = "en", style }) => (
  <div style={{ marginTop: "auto", flexShrink: 0, ...style }}>
    <div style={{ display: "flex", background: "var(--surface)", borderTop: "1px solid var(--line)", padding: "8px 8px 2px" }}>
      {NAV_ITEMS.map((it, i) => {
        const on = i === active;
        return (
          <span key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 3, padding: "4px 0", minHeight: 48 }}>
            <span style={{ width: 52, height: 30, borderRadius: 99, display: "grid", placeItems: "center",
              background: on ? "var(--primary-soft)" : "transparent",
              color: on ? "var(--on-primary-soft)" : "var(--ink-3)" }}>
              <QIcon name={it.icon} size={20} sw={on ? 2 : 1.7} fill={on && it.icon === "heart" ? "currentColor" : "none"}></QIcon>
            </span>
            <span className={lang === "bn" ? "t-bn" : lang === "ar" ? "t-ar" : ""} style={{ fontSize: 10.5, fontWeight: on ? 700 : 500, color: on ? "var(--ink)" : "var(--ink-3)" }}>{it[lang]}</span>
          </span>
        );
      })}
    </div>
    <HomeBar style={{ background: "var(--surface)" }}></HomeBar>
  </div>
);

/* ---------- compass dial ---------- */
const CompassDial = ({ heading = 254, size = 300, aligned, dark }) => {
  const ticks = [];
  for (let a = 0; a < 360; a += 6) ticks.push(a);
  const qiblaAt = 0; // needle drawn pointing up; ring rotates by -heading…aligned means needle up
  const ringRot = aligned ? 0 : 36; // visual offset when not aligned
  const C = size / 2;
  return (
    <div style={{ width: size, height: size, position: "relative" }}>
      <svg width={size} height={size} viewBox="0 0 300 300">
        {/* tick ring */}
        <g transform={`rotate(${-ringRot} 150 150)`}>
          {ticks.map((a) => (
            <line key={a} x1="150" y1="14" x2="150" y2={a % 90 === 0 ? 30 : a % 30 === 0 ? 26 : 21}
              stroke={a % 90 === 0 ? "var(--ink-2)" : "var(--line)"} strokeWidth={a % 30 === 0 ? 2.5 : 1.4}
              transform={`rotate(${a} 150 150)`} strokeLinecap="round"></line>
          ))}
          {[["N", 0], ["E", 90], ["S", 180], ["W", 270]].map(([t, a]) => (
            <text key={t} x="150" y="48" textAnchor="middle" fontSize="15" fontWeight="700"
              fill={a === 0 ? "var(--urgent)" : "var(--ink-3)"} fontFamily="var(--font-ui)"
              transform={`rotate(${a} 150 150)`}>{t}</text>
          ))}
        </g>
        {/* alignment arc at top */}
        <path d="M 132 17 A 135 135 0 0 1 168 17" fill="none" strokeWidth="5" strokeLinecap="round"
          stroke={aligned ? "var(--accent)" : "var(--line)"}></path>
        {/* needle */}
        <g transform={`rotate(${aligned ? 0 : -ringRot + qiblaAt} 150 150)`}>
          <path d="M150 58 L162 150 L150 138 L138 150 Z" fill={aligned ? "var(--accent)" : "var(--primary)"}></path>
          <line x1="150" y1="150" x2="150" y2="206" stroke="var(--line)" strokeWidth="3" strokeLinecap="round"></line>
        </g>
        <circle cx="150" cy="150" r="42" fill="var(--surface)" stroke="var(--line)"></circle>
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "grid", placeItems: "center" }}>
        <QalbMark size={40} color={aligned ? "var(--accent)" : "var(--primary)"} accent={aligned ? "var(--accent)" : "var(--primary)"} sw={3}></QalbMark>
      </div>
    </div>
  );
};

/* ---------- header (location + tri-calendar date) ---------- */
const AppHeader = ({ city = "Dhaka, Bangladesh", dates, lang = "en", trail, style }) => (
  <div style={{ padding: "8px 22px 0", flexShrink: 0, ...style }}>
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      <span style={{ display: "inline-flex", alignItems: "center", gap: 6, height: 38, padding: "0 13px", marginInlineStart: -10,
        borderRadius: 99, color: "var(--ink)", fontWeight: 700, fontSize: 15.5 }}>
        <QIcon name="pin" size={17} color="var(--primary)"></QIcon>{city}
        <QIcon name="chevD" size={15} color="var(--ink-3)"></QIcon>
      </span>
      <span style={{ flex: 1 }}></span>
      {trail || <QIcon name="bell" size={21} color="var(--ink-2)"></QIcon>}
    </div>
    <div className="t-caption c-2" style={{ marginTop: 2, display: "flex", flexWrap: "wrap", gap: "2px 7px", alignItems: "center" }}>
      {(dates || ["Fri 12 Jun 2026", "26 Dhul-Ḥijjah 1447", "২৯ জ্যৈষ্ঠ ১৪৩৩"]).map((d, i) => (
        <React.Fragment key={i}>
          {i > 0 && <span style={{ opacity: 0.5 }}>·</span>}
          <span className={/[\u0980-\u09FF]/.test(d) ? "t-bn" : ""}>{d}</span>
        </React.Fragment>
      ))}
    </div>
  </div>
);

/* ---------- notification mockup cards ---------- */
const NotifCard = ({ os = "android", app = "Qalbee", time = "now", title, body, actions, tone, dark, style }) => (
  <div className={dark ? "q-dark" : "q-light"} style={{ background: "var(--surface)", borderRadius: 18, padding: "13px 15px",
    boxShadow: "var(--e-2)", border: "1px solid var(--line)", fontFamily: "var(--font-ui)", color: "var(--ink)", ...style }}>
    <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
      <span style={{ width: 17, height: 17, borderRadius: os === "android" ? 99 : 4.5, background: tone || "var(--primary)", display: "grid", placeItems: "center" }}>
        <svg width="11" height="11" viewBox="0 0 96 96"><path d={HEART_PATH} fill="var(--on-primary)" transform="scale(1.25) translate(-9 -12)"></path></svg>
      </span>
      <span className="t-caption" style={{ fontWeight: 600, color: "var(--ink-2)" }}>{app}</span>
      <span className="t-caption c-3">· {time}</span>
      <span style={{ flex: 1 }}></span>
      <QIcon name="chevD" size={14} color="var(--ink-3)"></QIcon>
    </div>
    <div className="t-title-sm" style={{ marginTop: 7, fontSize: 14.5 }}>{title}</div>
    <div className="t-caption c-2" style={{ marginTop: 2, fontSize: 12.5, lineHeight: 1.45 }}>{body}</div>
    {actions && (
      <div style={{ display: "flex", gap: 18, marginTop: 11 }}>
        {actions.map((a, i) => (
          <span key={i} className="t-label" style={{ color: "var(--primary)", fontSize: 13 }}>{a}</span>
        ))}
      </div>
    )}
  </div>
);

/* ---------- spec annotation helpers (canvas-side, not in-app) ---------- */
const SpecNote = ({ children, style }) => (
  <div style={{ fontFamily: "var(--font-ui), system-ui", fontSize: 12, lineHeight: 1.5, color: "#6B6456",
    background: "#FBF7EC", border: "1px solid #E8E0CC", borderRadius: 10, padding: "9px 12px", ...style }}>{children}</div>
);
const SpecLabel = ({ children, style }) => (
  <div style={{ fontFamily: "ui-monospace, monospace", fontSize: 10.5, letterSpacing: .4, color: "#8A8273",
    textTransform: "uppercase", margin: "16px 0 8px", ...style }}>{children}</div>
);

Object.assign(window, {
  CountdownCard, PrayerTable, TrackerShell, TrackerToggle, TrackerCount, TrackerDuration,
  Heatmap, HM_LEVELS, ProgressRing, BottomNav, NAV_ITEMS, CompassDial, AppHeader, NotifCard,
  SpecNote, SpecLabel,
});
