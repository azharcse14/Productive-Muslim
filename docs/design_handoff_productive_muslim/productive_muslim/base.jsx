// productive_muslim/base.jsx — shared primitives: motif, icons, phone frame, controls
/* global React */
const { useState } = React;

/* ---------- digits ---------- */
const bnD = (s) => String(s).replace(/\d/g, (d) => "০১২৩৪৫৬৭৮৯"[d]);
const arD = (s) => String(s).replace(/\d/g, (d) => "٠١٢٣٤٥٦٧٨٩"[d]);

/* ---------- signature motif: 8-fold star + qalb heart ---------- */
const HEART_PATH =
  "M48 62.5s-12.3-7.4-15.4-14.8c-2.2-5.3.9-10.4 6.1-10.4 3.4 0 6.4 2 9.3 5.4 2.9-3.4 5.9-5.4 9.3-5.4 5.2 0 8.3 5.1 6.1 10.4C60.3 55.1 48 62.5 48 62.5z";

const QalbMark = ({ size = 96, color = "currentColor", accent, sw = 2.4, heart = true }) => (
  <svg width={size} height={size} viewBox="0 0 96 96" fill="none" aria-hidden="true">
    <g stroke={color} strokeWidth={sw}>
      <rect x="21" y="21" width="54" height="54" rx="7"></rect>
      <rect x="21" y="21" width="54" height="54" rx="7" transform="rotate(45 48 48)"></rect>
    </g>
    {heart && <path d={HEART_PATH} fill={accent || color}></path>}
  </svg>
);

const Star8 = ({ size = 24, color = "currentColor", sw = 2 }) => (
  <svg width={size} height={size} viewBox="0 0 96 96" fill="none" aria-hidden="true">
    <g stroke={color} strokeWidth={sw * 3}>
      <rect x="21" y="21" width="54" height="54" rx="7"></rect>
      <rect x="21" y="21" width="54" height="54" rx="7" transform="rotate(45 48 48)"></rect>
    </g>
  </svg>
);

/* faint tiling of the motif — the only decorative layer allowed */
const MotifBg = ({ opacity = 0.05, color = "currentColor", cell = 96, style }) => (
  <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%", opacity, pointerEvents: "none", ...style }} aria-hidden="true">
    <defs>
      <pattern id={"qmotif" + cell} width={cell} height={cell} patternUnits="userSpaceOnUse">
        <g transform={`translate(${cell / 2} ${cell / 2}) scale(${cell / 240})`} stroke={color} strokeWidth="6" fill="none">
          <rect x="-54" y="-54" width="108" height="108" rx="14"></rect>
          <rect x="-54" y="-54" width="108" height="108" rx="14" transform="rotate(45)"></rect>
        </g>
      </pattern>
    </defs>
    <rect width="100%" height="100%" fill={`url(#qmotif${cell})`}></rect>
  </svg>
);

/* ---------- icon set (stroke, 24 viewBox) ---------- */
const QI = {
  pin: <><path d="M12 21.5c-4.2-4.5-7-7.8-7-11.3a7 7 0 1 1 14 0c0 3.5-2.8 6.8-7 11.3z"></path><circle cx="12" cy="10" r="2.6"></circle></>,
  gps: <><circle cx="12" cy="12" r="7"></circle><circle cx="12" cy="12" r="2.4" fill="currentColor" stroke="none"></circle><path d="M12 2v3M12 19v3M2 12h3M19 12h3"></path></>,
  bell: <><path d="M18 9.5a6 6 0 1 0-12 0c0 4.8-2 6-2 6h16s-2-1.2-2-6z"></path><path d="M10.3 19a2 2 0 0 0 3.4 0"></path></>,
  bellOff: <><path d="M18 9.5a6 6 0 0 0-9.7-4.7M6 9.5c0 4.8-2 6-2 6h13"></path><path d="M10.3 19a2 2 0 0 0 3.4 0"></path><path d="M4 4l16 16"></path></>,
  search: <><circle cx="11" cy="11" r="6.5"></circle><path d="M20 20l-4.3-4.3"></path></>,
  gear: <><circle cx="12" cy="12" r="3.2"></circle><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M18.7 5.3l-2.1 2.1M7.4 16.6l-2.1 2.1"></path></>,
  book: <><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2.5H20v19H6.5A2.5 2.5 0 0 1 4 19V5a2.5 2.5 0 0 1 2.5-2.5z"></path></>,
  heart: <path d="M12 20.5s-7.2-4.4-9.2-8.8C1.3 8.1 3.4 5 6.7 5c2.1 0 3.7 1.3 5.3 3.2C13.6 6.3 15.2 5 17.3 5c3.3 0 5.4 3.1 3.9 6.7-2 4.4-9.2 8.8-9.2 8.8z"></path>,
  beads: <><path d="M4 5.5c2.2 6.8 13.8 6.8 16 0"></path><circle cx="5.5" cy="13" r="2"></circle><circle cx="12" cy="16.5" r="2"></circle><circle cx="18.5" cy="13" r="2"></circle></>,
  compass: <><circle cx="12" cy="12" r="8.5"></circle><path d="M15.2 8.8l-2 5.2-4.4 1.2 2-5.2 4.4-1.2z"></path></>,
  cal: <><rect x="3.5" y="5" width="17" height="16" rx="2.5"></rect><path d="M3.5 9.5h17M8 2.8V6M16 2.8V6"></path></>,
  moon: <path d="M20 13.2A8.2 8.2 0 1 1 10.8 4a6.6 6.6 0 0 0 9.2 9.2z"></path>,
  sun: <><circle cx="12" cy="12" r="4"></circle><path d="M12 2.5V5M12 19v2.5M2.5 12H5M19 12h2.5M4.9 4.9l1.8 1.8M17.3 17.3l1.8 1.8M19.1 4.9l-1.8 1.8M6.7 17.3l-1.8 1.8"></path></>,
  check: <path d="M5 12.5l4.5 4.5L19 7.5"></path>,
  plus: <path d="M12 5v14M5 12h14"></path>,
  minus: <path d="M6 12h12"></path>,
  close: <path d="M6 6l12 12M18 6L6 18"></path>,
  chevD: <path d="M6.5 9.5l5.5 5.5 5.5-5.5"></path>,
  chevR: <path d="M9.5 6.5l5.5 5.5-5.5 5.5"></path>,
  chevL: <path d="M14.5 6.5L9 12l5.5 5.5"></path>,
  back: <path d="M19 12H5.5M11 17.5L5.5 12 11 6.5"></path>,
  share: <><path d="M12 14.5V3.5"></path><path d="M8 7l4-3.5L16 7"></path><path d="M5 11.5v8a1.5 1.5 0 0 0 1.5 1.5h11a1.5 1.5 0 0 0 1.5-1.5v-8"></path></>,
  copy: <><rect x="9" y="9" width="11.5" height="11.5" rx="2"></rect><path d="M5.5 15H4.8A1.8 1.8 0 0 1 3 13.2V4.8A1.8 1.8 0 0 1 4.8 3h8.4A1.8 1.8 0 0 1 15 4.8v.7"></path></>,
  bookmark: <path d="M6.5 3.5h11v17l-5.5-3.8-5.5 3.8z"></path>,
  play: <path d="M8.5 5.5l10 6.5-10 6.5z"></path>,
  lock: <><rect x="5" y="10.5" width="14" height="9.5" rx="2.5"></rect><path d="M8.2 10.5V7.2a3.8 3.8 0 0 1 7.6 0v3.3"></path></>,
  mosque: <><path d="M4 21h16M6 21v-6.5M18 21v-6.5"></path><path d="M6 14.5c0-4.2 3.2-5 6-8.2 2.8 3.2 6 4 6 8.2"></path><path d="M12 3.2v1.6"></path></>,
  home: <><path d="M3.5 10.8L12 3.5l8.5 7.3"></path><path d="M5.5 9.5V20.5h13V9.5"></path></>,
  dots: <><circle cx="5" cy="12" r="1.4" fill="currentColor" stroke="none"></circle><circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none"></circle><circle cx="19" cy="12" r="1.4" fill="currentColor" stroke="none"></circle></>,
  edit: <path d="M4 20l4.5-1L20 7.5l-3.5-3.5L5 15.5 4 20z"></path>,
  info: <><circle cx="12" cy="12" r="8.5"></circle><path d="M12 11v5"></path><circle cx="12" cy="8" r="0.5" fill="currentColor"></circle></>,
  globe: <><circle cx="12" cy="12" r="8.5"></circle><ellipse cx="12" cy="12" rx="3.8" ry="8.5"></ellipse><path d="M3.5 12h17"></path></>,
  clock: <><circle cx="12" cy="12" r="8.5"></circle><path d="M12 7.5V12l3.2 2"></path></>,
  spark: <path d="M12 3l1.9 5.6L19.5 10l-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.4L12 3z"></path>,
  archive: <><rect x="3.5" y="4" width="17" height="4.5" rx="1.2"></rect><path d="M5.5 8.5V19a1.5 1.5 0 0 0 1.5 1.5h10a1.5 1.5 0 0 0 1.5-1.5V8.5"></path><path d="M10 12.5h4"></path></>,
  kaaba: <><rect x="5" y="6" width="14" height="14.5" rx="1"></rect><path d="M5 10.2h14"></path></>,
  reset: <><path d="M3.5 12a8.5 8.5 0 1 0 2.6-6.1L3.5 8.5"></path><path d="M3.5 3.5v5h5"></path></>,
  fingerprint: <><path d="M7 13.5c0-2.8 2.2-5 5-5s5 2.2 5 5c0 2.4-.3 4.6-1 6.5"></path><path d="M12 13.5c0 2.7-.4 5.1-1.4 7"></path><path d="M4.6 9.5A8.9 8.9 0 0 1 12 5.6c2.5 0 4.7 1 6.4 2.6"></path></>,
  grid: <><rect x="4" y="4" width="6.5" height="6.5" rx="1.5"></rect><rect x="13.5" y="4" width="6.5" height="6.5" rx="1.5"></rect><rect x="4" y="13.5" width="6.5" height="6.5" rx="1.5"></rect><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="1.5"></rect></>,
  food: <><path d="M4 11.5h16a8 8 0 0 1-16 0z"></path><path d="M9 8.5c0-1.5 1-1.5 1-3M13.5 8.5c0-1.5 1-1.5 1-3"></path></>,
  trend: <path d="M3.5 17l5-5.5 3.5 3L20.5 7M16 7h4.5V11.5"></path>,
};
const QIcon = ({ name, size = 22, color = "currentColor", sw = 1.7, style, fill }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={fill || "none"} stroke={color}
    strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" style={style} aria-hidden="true">
    {QI[name] || null}
  </svg>
);

/* ---------- phone frame ---------- */
const StatusBar = ({ dir, dark, time = "5:41" }) => (
  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "14px 22px 6px", fontSize: 13.5, fontWeight: 600, fontVariantNumeric: "tabular-nums", flexShrink: 0 }}>
    <span>{time}</span>
    <svg width="58" height="12" viewBox="0 0 58 12" fill="currentColor" aria-hidden="true">
      <rect x="0" y="7" width="2.6" height="4" rx="1"></rect><rect x="4.2" y="5" width="2.6" height="6" rx="1"></rect><rect x="8.4" y="3" width="2.6" height="8" rx="1"></rect><rect x="12.6" y="1" width="2.6" height="10" rx="1"></rect>
      <path d="M24 9.8a4.6 4.6 0 0 1 6 0l-3 3-3-3zM21.4 7a8.3 8.3 0 0 1 11.2 0l-1.7 1.7a5.9 5.9 0 0 0-7.8 0L21.4 7z"></path>
      <rect x="38" y="1.5" width="16" height="9" rx="2.6" fill="none" stroke="currentColor" strokeOpacity=".45"></rect>
      <rect x="40" y="3.5" width="9" height="5" rx="1.2"></rect><rect x="55" y="4.5" width="2" height="3" rx="1" fillOpacity=".45"></rect>
    </svg>
  </div>
);

const Phone = ({ dark, w = 390, h = 844, dir = "ltr", children, time, bare, style }) => (
  <div dir={dir} className={"q-screen " + (dark ? "q-dark" : "q-light")} style={{ width: w, height: h, ...style }}>
    {!bare && <StatusBar dir={dir} dark={dark} time={time}></StatusBar>}
    {children}
  </div>
);

const HomeBar = ({ style }) => (
  <div style={{ display: "flex", justifyContent: "center", padding: "6px 0 8px", flexShrink: 0, ...style }}>
    <div style={{ width: 120, height: 4.5, borderRadius: 3, background: "currentColor", opacity: 0.22 }}></div>
  </div>
);

/* ---------- controls ---------- */
const Btn = ({ kind = "primary", state, children, icon, full, small, style }) => {
  const base = {
    display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
    minHeight: small ? 40 : 52, padding: small ? "0 18px" : "0 26px",
    borderRadius: "var(--r-full)", fontFamily: "var(--font-ui)",
    fontSize: small ? 14 : 15.5, fontWeight: 600, border: "1.5px solid transparent",
    width: full ? "100%" : undefined, position: "relative", cursor: "default",
  };
  const kinds = {
    primary: { background: "var(--primary)", color: "var(--on-primary)" },
    tonal: { background: "var(--primary-soft)", color: "var(--on-primary-soft)" },
    outline: { background: "transparent", color: "var(--primary)", borderColor: "var(--primary)" },
    ghost: { background: "transparent", color: "var(--primary)" },
    accent: { background: "var(--accent)", color: "#231603" },
  };
  const states = {
    pressed: { filter: "brightness(.88)", transform: "scale(.985)" },
    disabled: { opacity: 0.38 },
    focused: { boxShadow: "0 0 0 3px var(--bg), 0 0 0 5.5px var(--primary)" },
  };
  return (
    <span style={{ ...base, ...kinds[kind], ...(states[state] || {}), ...style }}>
      {icon && <QIcon name={icon} size={small ? 17 : 19}></QIcon>}{children}
    </span>
  );
};

const Toggle = ({ on, disabled }) => (
  <span style={{ width: 46, height: 28, borderRadius: 99, flexShrink: 0, padding: 3, display: "inline-flex",
    justifyContent: on ? "flex-end" : "flex-start",
    background: on ? "var(--primary)" : "var(--surface-2)",
    border: on ? "1.5px solid var(--primary)" : "1.5px solid var(--line)",
    opacity: disabled ? 0.4 : 1 }}>
    <span style={{ width: 21, height: 21, borderRadius: 99, background: on ? "var(--on-primary)" : "var(--ink-3)" }}></span>
  </span>
);

const Chip = ({ active, children, icon, style }) => (
  <span style={{ display: "inline-flex", alignItems: "center", gap: 6, height: 36, padding: "0 15px",
    borderRadius: 99, fontSize: 13.5, fontWeight: 600, whiteSpace: "nowrap",
    background: active ? "var(--primary)" : "var(--surface)",
    color: active ? "var(--on-primary)" : "var(--ink-2)",
    border: active ? "1.5px solid var(--primary)" : "1.5px solid var(--line)", ...style }}>
    {icon && <QIcon name={icon} size={15}></QIcon>}{children}
  </span>
);

const Card = ({ children, style, pad = 18, tone }) => (
  <div style={{ background: tone || "var(--surface)", borderRadius: "var(--r-lg)", padding: pad,
    boxShadow: "var(--e-1)", border: "1px solid var(--line)", position: "relative", overflow: "hidden", ...style }}>
    {children}
  </div>
);

const ListRow = ({ icon, title, sub, trail, style, iconTone }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 14, minHeight: 56, padding: "10px 2px", ...style }}>
    {icon && (
      <span style={{ width: 38, height: 38, borderRadius: 12, flexShrink: 0, display: "grid", placeItems: "center",
        background: iconTone || "var(--primary-soft)", color: "var(--on-primary-soft)" }}>
        <QIcon name={icon} size={19}></QIcon>
      </span>
    )}
    <span style={{ flex: 1, minWidth: 0 }}>
      <span className="t-title-sm" style={{ display: "block" }}>{title}</span>
      {sub && <span className="t-caption c-2" style={{ display: "block", marginTop: 1 }}>{sub}</span>}
    </span>
    {trail}
  </div>
);

const Radio = ({ on }) => (
  <span style={{ width: 22, height: 22, borderRadius: 99, flexShrink: 0, display: "grid", placeItems: "center",
    border: on ? "6.5px solid var(--primary)" : "2px solid var(--ink-3)" }}></span>
);
const CheckBox = ({ on }) => (
  <span style={{ width: 23, height: 23, borderRadius: 7, flexShrink: 0, display: "grid", placeItems: "center",
    background: on ? "var(--primary)" : "transparent", color: "var(--on-primary)",
    border: on ? "2px solid var(--primary)" : "2px solid var(--ink-3)" }}>
    {on && <QIcon name="check" size={14} sw={2.6}></QIcon>}
  </span>
);

const SegControl = ({ opts, active, style }) => (
  <div style={{ display: "flex", gap: 4, padding: 4, background: "var(--surface-2)", borderRadius: 14, ...style }}>
    {opts.map((o, i) => (
      <span key={i} style={{ flex: 1, textAlign: "center", padding: "9px 8px", borderRadius: 10, fontSize: 13.5, fontWeight: 600,
        background: i === active ? "var(--surface)" : "transparent",
        color: i === active ? "var(--ink)" : "var(--ink-2)",
        boxShadow: i === active ? "var(--e-1)" : "none" }}>{o}</span>
    ))}
  </div>
);

const Field = ({ label, value, placeholder, focus, icon, trail, style }) => (
  <div style={style}>
    {label && <div className="t-label c-2" style={{ marginBottom: 7 }}>{label}</div>}
    <div style={{ display: "flex", alignItems: "center", gap: 10, height: 52, padding: "0 16px",
      borderRadius: "var(--r-md)", background: "var(--surface)",
      border: focus ? "2px solid var(--primary)" : "1.5px solid var(--line)",
      boxShadow: focus ? "0 0 0 3.5px var(--primary-soft)" : "none" }}>
      {icon && <QIcon name={icon} size={19} style={{ color: "var(--ink-3)" }}></QIcon>}
      <span className="t-body" style={{ flex: 1, color: value ? "var(--ink)" : "var(--ink-3)" }}>{value || placeholder}</span>
      {focus && <span style={{ width: 2, height: 22, background: "var(--primary)", marginInlineStart: -6 }}></span>}
      {trail}
    </div>
  </div>
);

const Stepper = ({ val, dim }) => (
  <span style={{ display: "inline-flex", alignItems: "center", gap: 2, background: "var(--surface-2)", borderRadius: 99, padding: 3, opacity: dim ? 0.5 : 1 }}>
    <span style={{ width: 34, height: 34, borderRadius: 99, display: "grid", placeItems: "center", background: "var(--surface)", boxShadow: "var(--e-1)" }}><QIcon name="minus" size={16}></QIcon></span>
    <span className="t-title-sm t-num" style={{ minWidth: 34, textAlign: "center" }}>{val}</span>
    <span style={{ width: 34, height: 34, borderRadius: 99, display: "grid", placeItems: "center", background: "var(--surface)", boxShadow: "var(--e-1)" }}><QIcon name="plus" size={16}></QIcon></span>
  </span>
);

const Banner = ({ icon = "info", children, tone = "var(--primary-soft)", color = "var(--on-primary-soft)", style }) => (
  <div style={{ display: "flex", gap: 10, padding: "12px 14px", borderRadius: "var(--r-md)", background: tone, color, alignItems: "flex-start", ...style }}>
    <QIcon name={icon} size={18} style={{ flexShrink: 0, marginTop: 1 }}></QIcon>
    <span className="t-caption" style={{ fontSize: 12.5, lineHeight: 1.45 }}>{children}</span>
  </div>
);

/* skeleton shimmer block */
const Skel = ({ w = "100%", h = 14, r = 7, style }) => (
  <span style={{ display: "block", width: w, height: h, borderRadius: r, background: "var(--surface-2)", ...style }}></span>
);

Object.assign(window, {
  bnD, arD, QalbMark, Star8, MotifBg, QIcon, HEART_PATH,
  Phone, StatusBar, HomeBar,
  Btn, Toggle, Chip, Card, ListRow, Radio, CheckBox, SegControl, Field, Stepper, Banner, Skel,
});
