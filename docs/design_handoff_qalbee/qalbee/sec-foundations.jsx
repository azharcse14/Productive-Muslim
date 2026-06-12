// qalbee/sec-foundations.jsx — tokens & theme spec boards
/* global React, DCArtboard, QalbMark, Star8, MotifBg, QIcon, SpecLabel, SpecNote, bnD, arD */

const Swatch = ({ name, hex, varName, on, border }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 8 }}>
    <span style={{ width: 52, height: 40, borderRadius: 10, background: `var(${varName})`, flexShrink: 0,
      border: border ? "1px solid var(--line)" : "none", display: "grid", placeItems: "center" }}>
      {on && <span style={{ fontSize: 11, fontWeight: 700, color: `var(${on})` }}>Aa</span>}
    </span>
    <span style={{ flex: 1 }}>
      <span className="t-label" style={{ display: "block", fontSize: 12.5 }}>{name}</span>
      <span className="t-caption c-3" style={{ fontFamily: "ui-monospace,monospace", fontSize: 10.5 }}>{varName.replace("--", "")} · {hex}</span>
    </span>
  </div>
);

const PaletteBoard = ({ dark }) => (
  <div className={dark ? "q-dark" : "q-light"} style={{ padding: 24, background: "var(--bg)", color: "var(--ink)", height: "100%", fontFamily: "var(--font-ui)" }}>
    <SpecLabel style={{ marginTop: 0, color: "var(--ink-3)" }}>Surfaces</SpecLabel>
    <Swatch name="background" hex={dark ? "#0E1513" : "#F6F4EE"} varName="--bg" border></Swatch>
    <Swatch name="surface" hex={dark ? "#16201D" : "#FFFFFF"} varName="--surface" border></Swatch>
    <Swatch name="surfaceAlt" hex={dark ? "#1D2A26" : "#EFEBE1"} varName="--surface-2" border></Swatch>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Ink</SpecLabel>
    <Swatch name="ink / onSurface" hex={dark ? "#E4E9E4" : "#1F2A26"} varName="--ink"></Swatch>
    <Swatch name="inkMuted" hex={dark ? "#9BABA3" : "#5A6661"} varName="--ink-2"></Swatch>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Brand</SpecLabel>
    <Swatch name="primary — qalb teal" hex={dark ? "#79C7B6" : "#15564D"} varName="--primary" on="--on-primary"></Swatch>
    <Swatch name="primaryContainer" hex={dark ? "#1C332D" : "#DCE9E4"} varName="--primary-soft" on="--on-primary-soft"></Swatch>
    <Swatch name="accentWarm — honey" hex={dark ? "#E2B264" : "#C08A2E"} varName="--accent"></Swatch>
    <Swatch name="accentWarmContainer" hex={dark ? "#322817" : "#F4E6C8"} varName="--accent-soft" on="--on-accent-soft"></Swatch>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Semantic countdown — AA on this bg</SpecLabel>
    <Swatch name="stateOk · time remaining" hex={dark ? "#84C9A0" : "#246B45"} varName="--ok"></Swatch>
    <Swatch name="stateSoon · jamaat ≤ 10 min" hex={dark ? "#E2B264" : "#8F5E12"} varName="--warn"></Swatch>
    <Swatch name="stateUrgent · makruh window" hex={dark ? "#E78D77" : "#A93B29"} varName="--urgent"></Swatch>
    {dark && <SpecNote style={{ marginTop: 14, background: "var(--surface)", borderColor: "var(--line)", color: "var(--ink-2)" }}>
      Dark is designed, not inverted: teal-black base (never #000), soft white ink (never #FFF), lifted low-chroma brand colors. Comfortable at Fajr/Tahajjud.</SpecNote>}
  </div>
);

const TypeBoard = () => (
  <div className="q-light" style={{ padding: 24, background: "var(--bg)", color: "var(--ink)", height: "100%", fontFamily: "var(--font-ui)" }}>
    <SpecLabel style={{ marginTop: 0 }}>Latin / UI — Schibsted Grotesk (variable)</SpecLabel>
    {[["display", "34/38 · 700", "Asr begins"], ["headline", "26/31 · 700", "Asr begins"], ["title", "19/24 · 600", "Asr begins soon"],
      ["title-sm", "16.5/21 · 600", "Asr begins soon"], ["body", "15/22.5 · 400", "Accurate prayer times, anywhere on earth."],
      ["label", "13/17.5 · 600", "MARK AS PRAYED"], ["caption", "11.5/16 · 500", "Affects Asr time only"]].map(([cls, spec, txt]) => (
      <div key={cls} style={{ display: "flex", alignItems: "baseline", gap: 12, marginBottom: 9 }}>
        <span className="t-caption c-3" style={{ width: 96, fontFamily: "ui-monospace,monospace", fontSize: 10, flexShrink: 0 }}>{cls} · {spec}</span>
        <span className={"t-" + cls} style={{ whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{txt}</span>
      </div>
    ))}
    <SpecLabel>Bengali — Noto Sans Bengali (full conjunct support)</SpecLabel>
    <div className="t-bn" style={{ fontSize: 21, fontWeight: 600 }}>আসরের সময় হয়েছে</div>
    <div className="t-bn t-body c-2" style={{ marginTop: 3 }}>পৃথিবীর যেকোনো শহরে নির্ভুল নামাজের সময়সূচি — সম্পূর্ণ অফলাইনে।</div>
    <SpecLabel>Quran Arabic — KFGQPC Uthmanic HAFS (certified mushaf; preview rendered in stand-in)</SpecLabel>
    <div className="t-quran" style={{ fontSize: 30, lineHeight: 2 }}>بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ</div>
    <SpecLabel>UI Arabic — IBM Plex Sans Arabic</SpecLabel>
    <div className="t-ar" dir="rtl" style={{ fontSize: 17, fontWeight: 600 }}>حان وقت العصر · الإعدادات</div>
    <SpecLabel>Numerals by locale</SpecLabel>
    <div className="t-num" style={{ fontSize: 22, fontWeight: 700, display: "flex", gap: 22, alignItems: "baseline" }}>
      <span>04:38</span><span className="t-bn">{bnD("04:38")}</span><span className="t-quran" style={{ fontSize: 24 }}>{arD("04:38")}</span>
    </div>
    <SpecNote style={{ marginTop: 14 }}>Quran reader carries its own independent user scale (22–44px Arabic, steps of 2). System font scaling honored to 1.5× on all UI styles — layouts wrap, never truncate.</SpecNote>
  </div>
);

const MetricsBoard = () => (
  <div className="q-light" style={{ padding: 24, background: "var(--bg)", color: "var(--ink)", height: "100%", fontFamily: "var(--font-ui)" }}>
    <SpecLabel style={{ marginTop: 0 }}>Spacing — 4pt grid</SpecLabel>
    <div style={{ display: "flex", gap: 10, alignItems: "flex-end" }}>
      {[4, 8, 12, 16, 20, 24, 32, 40].map((s) => (
        <div key={s} style={{ textAlign: "center" }}>
          <div style={{ width: s, height: s, background: "var(--primary-soft)", border: "1px solid var(--primary)", borderRadius: 3, margin: "0 auto" }}></div>
          <div className="t-caption c-3" style={{ fontSize: 9.5, marginTop: 4 }}>{s}</div>
        </div>
      ))}
    </div>
    <SpecLabel>Radius</SpecLabel>
    <div style={{ display: "flex", gap: 12 }}>
      {[["sm", 10], ["md", 14], ["lg", 20], ["xl", 28], ["full", 99]].map(([n, r]) => (
        <div key={n} style={{ textAlign: "center" }}>
          <div style={{ width: 56, height: 44, borderRadius: r, background: "var(--surface)", border: "1.5px solid var(--primary)" }}></div>
          <div className="t-caption c-3" style={{ fontSize: 10, marginTop: 4 }}>{n} · {r === 99 ? "pill" : r}</div>
        </div>
      ))}
    </div>
    <SpecLabel>Elevation — 2 levels only</SpecLabel>
    <div style={{ display: "flex", gap: 16, padding: "6px 0 10px" }}>
      <div style={{ width: 130, height: 64, borderRadius: 16, background: "var(--surface)", boxShadow: "var(--e-1)", display: "grid", placeItems: "center" }} className="t-caption c-2">e-1 · resting card</div>
      <div style={{ width: 130, height: 64, borderRadius: 16, background: "var(--surface)", boxShadow: "var(--e-2)", display: "grid", placeItems: "center" }} className="t-caption c-2">e-2 · sheet/dialog</div>
    </div>
    <SpecLabel>Touch targets</SpecLabel>
    <div className="t-caption c-2">Minimum 48×48dp everywhere; tasbih tap surface is the full screen body.</div>
    <SpecLabel>Motion</SpecLabel>
    {[["fast · 120ms", "state changes, ripples, countdown tick"], ["med · 240ms", "sheets, page transitions, tab switch"],
      ["slow · 420ms", "splash mark, streak celebration, qibla lock"]].map(([d, u]) => (
      <div key={d} style={{ display: "flex", gap: 10, marginBottom: 5 }}>
        <span className="t-label" style={{ width: 110, fontSize: 12, color: "var(--primary)" }}>{d}</span>
        <span className="t-caption c-2">{u}</span>
      </div>
    ))}
    <SpecNote style={{ marginTop: 10 }}>Ease: cubic-bezier(.4,0,.2,1). All signature motion is disabled under reduced-motion — states cut, never animate.</SpecNote>
  </div>
);

const MotifBoard = () => (
  <div className="q-light" style={{ padding: 24, background: "var(--bg)", color: "var(--ink)", height: "100%", fontFamily: "var(--font-ui)" }}>
    <div style={{ display: "flex", gap: 20, alignItems: "center" }}>
      <QalbMark size={104} color="var(--primary)" accent="var(--accent)"></QalbMark>
      <div>
        <div className="t-title">The qalb mark</div>
        <div className="t-caption c-2" style={{ marginTop: 4, maxWidth: 230 }}>One motif, everywhere: an 8-fold star (two interlaced squares) holding the heart. The star is order and discipline; the heart is what it protects.</div>
      </div>
    </div>
    <SpecLabel>Derived uses — applied with restraint</SpecLabel>
    <div style={{ display: "flex", gap: 14, alignItems: "center", marginBottom: 14 }}>
      <Star8 size={30} color="var(--primary)"></Star8>
      <span className="t-caption c-2">section divider / bullet — star only, 1.5px stroke</span>
    </div>
    <div style={{ position: "relative", height: 86, borderRadius: 14, background: "var(--surface)", border: "1px solid var(--line)", overflow: "hidden", marginBottom: 14 }}>
      <MotifBg opacity={0.06} cell={72} style={{ color: "var(--primary)" }}></MotifBg>
      <div style={{ position: "relative", padding: 14 }} className="t-caption c-2">background tiling — max 6% opacity, hero cards & splash only</div>
    </div>
    <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
      <svg width="120" height="14" viewBox="0 0 120 14">
        <line x1="0" y1="7" x2="46" y2="7" stroke="var(--line)" strokeWidth="1.5"></line>
        <g transform="translate(60 7) scale(.055)" stroke="var(--primary)" strokeWidth="14" fill="none">
          <rect x="-54" y="-54" width="108" height="108" rx="14"></rect>
          <rect x="-54" y="-54" width="108" height="108" rx="14" transform="rotate(45)"></rect>
        </g>
        <line x1="74" y1="7" x2="120" y2="7" stroke="var(--line)" strokeWidth="1.5"></line>
      </svg>
      <span className="t-caption c-2">content divider with star pivot</span>
    </div>
    <SpecLabel>Rules</SpecLabel>
    <div className="t-caption c-2" style={{ lineHeight: 1.7 }}>
      Never more than one motif treatment per screen · never above 6% opacity as texture · never rotated off-axis · the heart appears only in the full mark, app icon, and Muhasaba tab.
    </div>
  </div>
);

const SecFoundations = () => (
  <DCSection id="foundations" title="01 · Foundations — tokens & theme spec" subtitle="Colors, type, spacing, radius, elevation, motion · maps 1:1 to Flutter ThemeData">
    <DCArtboard id="f-pal-l" label="Palette · Light" width={400} height={870}><PaletteBoard></PaletteBoard></DCArtboard>
    <DCArtboard id="f-pal-d" label="Palette · Dark (Fajr-comfortable)" width={400} height={870}><PaletteBoard dark></PaletteBoard></DCArtboard>
    <DCArtboard id="f-type" label="Type — three script systems" width={460} height={870}><TypeBoard></TypeBoard></DCArtboard>
    <DCArtboard id="f-metrics" label="Spacing · Radius · Elevation · Motion" width={440} height={680}><MetricsBoard></MetricsBoard></DCArtboard>
    <DCArtboard id="f-motif" label="Signature motif — the qalb mark" width={440} height={680}><MotifBoard></MotifBoard></DCArtboard>
  </DCSection>
);

window.SecFoundations = SecFoundations;
