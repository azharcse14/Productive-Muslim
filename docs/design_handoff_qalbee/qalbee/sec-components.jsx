// qalbee/sec-components.jsx — core component library
/* global React, DCArtboard, DCSection, CountdownCard, PrayerTable, TrackerToggle, TrackerCount, TrackerDuration,
   Heatmap, HM_LEVELS, ProgressRing, BottomNav, CompassDial, Btn, Toggle, Chip, Field, SegControl, Radio, CheckBox,
   Stepper, Skel, QIcon, QalbMark, SpecLabel, SpecNote, bnD */

const CBoard = ({ dark, children, pad = 22 }) => (
  <div className={dark ? "q-dark" : "q-light"} style={{ padding: pad, background: "var(--bg)", color: "var(--ink)", height: "100%", fontFamily: "var(--font-ui)" }}>
    {children}
  </div>
);

/* ---- countdown card states ---- */
const CountdownBoard = ({ dark }) => (
  <CBoard dark={dark}>
    <SpecLabel style={{ marginTop: 0, color: "var(--ink-3)" }}>1 · calm — time remaining (&gt; 30 min)</SpecLabel>
    <CountdownCard state="calm" eyebrow="Asr · ends in" big="2:41:09" sub="Next: Maghrib at 6:49 PM" pct={0.35}></CountdownCard>
    <SpecLabel style={{ color: "var(--ink-3)" }}>2 · soon — jamaat ≤ 10 min</SpecLabel>
    <CountdownCard state="amber" eyebrow="Asr · jamaat in" big="08:42" sub="Jamaat 5:15 PM · Masjid An-Noor" pct={0.82}></CountdownCard>
    <SpecLabel style={{ color: "var(--ink-3)" }}>3 · urgent — last 20 min of waqt (makruh)</SpecLabel>
    <CountdownCard state="urgent" eyebrow="Asr · ends in" big="14:06" sub="Maghrib begins 6:49 PM" pct={0.94}></CountdownCard>
    <SpecLabel style={{ color: "var(--ink-3)" }}>4 · Ramadan override — pre-Fajr</SpecLabel>
    <CountdownCard state="sahri" eyebrow="Sahri ends in" big="42:18" sub="Fajr begins 3:43 AM · eat & drink until then" pct={0.7}></CountdownCard>
    <SpecLabel style={{ color: "var(--ink-3)" }}>5 · Ramadan override — Asr→Maghrib</SpecLabel>
    <CountdownCard state="iftar" eyebrow="Iftar in" big="1:12:33" sub="Maghrib 6:49 PM · may it be accepted" pct={0.61}></CountdownCard>
  </CBoard>
);

/* ---- prayer table spec ---- */
const prayerRows = [
  { name: "Fajr", time: "3:43 – 5:10 AM", jamaat: "4:15", done: true },
  { name: "Sunrise", time: "5:10 AM", sunrise: true },
  { name: "Dhuhr", time: "12:00 – 4:38 PM", jamaat: "1:30", done: true },
  { name: "Asr", time: "4:38 – 6:49 PM", jamaat: "5:15" },
  { name: "Maghrib", time: "6:49 – 8:15 PM", jamaat: "6:54" },
  { name: "Isha", time: "8:15 PM – 3:43 AM" },
];
const PrayerTableBoard = ({ dark }) => (
  <CBoard dark={dark}>
    <SpecLabel style={{ marginTop: 0, color: "var(--ink-3)" }}>Daily table — current waqt highlighted (Asr)</SpecLabel>
    <PrayerTable rows={prayerRows} activeIdx={3}></PrayerTable>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Row anatomy</SpecLabel>
    <div className="t-caption c-2" style={{ lineHeight: 1.75 }}>
      ① waqt dot — teal = current · green = prayed · neutral = upcoming<br></br>
      ② name (84dp min, wraps for Bengali) · ③ start–end, tabular numerals<br></br>
      ④ jamaat time, or quiet underlined “Set jamaat” when unconfigured — never a nag<br></br>
      ⑤ check affordance → writes directly to today’s Muhasaba entry<br></br>
      Sunrise is a 42dp info row: no jamaat, no check.
    </div>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Bengali locale — labels 1.5–2× longer, nothing truncates</SpecLabel>
    <PrayerTable rows={[
      { name: <span className="t-bn">ফজর</span>, time: bnD("3:43 – 5:10 AM"), jamaat: bnD("4:15"), done: true },
      { name: <span className="t-bn">আসর</span>, time: bnD("4:38 – 6:49 PM"), jamaat: bnD("5:15") },
      { name: <span className="t-bn">মাগরিব</span>, time: bnD("6:49 – 8:15 PM") },
    ]} activeIdx={1} labels={{ set: "জামাত দিন" }}></PrayerTable>
  </CBoard>
);

/* ---- tracker items ---- */
const TrackerBoard = ({ dark }) => (
  <CBoard dark={dark}>
    <SpecLabel style={{ marginTop: 0, color: "var(--ink-3)" }}>Type A · yes/no toggle</SpecLabel>
    <TrackerToggle icon="book" label="Read Quran" sub="Any amount counts" on></TrackerToggle>
    <div style={{ height: 10 }}></div>
    <TrackerToggle icon="moon" label="Tahajjud" off></TrackerToggle>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Type B · count stepper with target</SpecLabel>
    <TrackerCount icon="beads" label="Azkar sessions" sub="Target 3 / day" val={2}></TrackerCount>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Type C · duration</SpecLabel>
    <TrackerDuration icon="clock" label="Quran study" sub="Target 20 min" val="25 min"></TrackerDuration>
    <div style={{ height: 10 }}></div>
    <TrackerDuration icon="clock" label="Quran study" sub="Tap to log time" placeholder="0 min"></TrackerDuration>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Interactive states</SpecLabel>
    <TrackerToggle icon="heart" label="Pressed" state="pressed" on></TrackerToggle>
    <div style={{ height: 10 }}></div>
    <TrackerToggle icon="heart" label="Focused (keyboard / switch access)" state="focused"></TrackerToggle>
    <div style={{ height: 10 }}></div>
    <TrackerToggle icon="heart" label="Disabled (archived item)" state="disabled"></TrackerToggle>
    <SpecNote style={{ marginTop: 16, background: "var(--surface)", borderColor: "var(--line)", color: "var(--ink-2)" }}>
      Unmet targets stay neutral — no red, no “failed”. The only colored state is completion (teal/green family).</SpecNote>
  </CBoard>
);

/* ---- heatmap + ring ---- */
const week = (a) => a;
const HeatBoard = ({ dark }) => (
  <CBoard dark={dark}>
    <SpecLabel style={{ marginTop: 0, color: "var(--ink-3)" }}>Heatmap cell — 5 intensity levels</SpecLabel>
    <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
      <span className="t-caption c-3">0%</span>
      {HM_LEVELS.map((c, i) => <span key={i} style={{ width: 22, height: 22, borderRadius: 6, background: c }}></span>)}
      <span className="t-caption c-3">100%</span>
    </div>
    <div className="t-caption c-2" style={{ marginTop: 8, lineHeight: 1.6 }}>
      Intensity = day completion %, quantized to quartiles. Level 0 is a visible neutral — an empty day is “not yet”, never an alarm. Cell 13dp, gap 3.5dp, radius 3.5.
    </div>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Month in context</SpecLabel>
    <Heatmap data={[
      week([-1, -1, 1, 2, 3, 2, 4]), week([3, 4, 2, 1, 0, 2, 3]), week([4, 4, 3, 2, 3, 4, 4]),
      week([2, 3, 4, 4, 3, 2, 1]), week([0, 2, 3, 4, -1, -1, -1]),
    ]}></Heatmap>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Progress ring — dashboards & tasbih</SpecLabel>
    <div style={{ display: "flex", gap: 18, alignItems: "center" }}>
      <ProgressRing pct={0.78} size={108}>
        <div className="t-headline t-num" style={{ fontSize: 24 }}>78%</div>
        <div className="t-caption c-2" style={{ fontSize: 10 }}>this week</div>
      </ProgressRing>
      <ProgressRing pct={0.33} size={76} sw={7} color="var(--accent)">
        <div className="t-title t-num" style={{ fontSize: 17 }}>33</div>
      </ProgressRing>
      <div className="t-caption c-2" style={{ flex: 1, lineHeight: 1.55 }}>Round caps; track is surfaceAlt. Accent ring reserved for tasbih & celebrations.</div>
    </div>
  </CBoard>
);

/* ---- buttons & inputs ---- */
const ButtonBoard = ({ dark }) => (
  <CBoard dark={dark}>
    <SpecLabel style={{ marginTop: 0, color: "var(--ink-3)" }}>Buttons — default / pressed / disabled / focused</SpecLabel>
    {["primary", "tonal", "outline", "ghost"].map((k) => (
      <div key={k} style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 10, alignItems: "center" }}>
        <Btn kind={k} small>{k}</Btn>
        <Btn kind={k} small state="pressed">pressed</Btn>
        <Btn kind={k} small state="disabled">disabled</Btn>
        <Btn kind={k} small state="focused">focused</Btn>
      </div>
    ))}
    <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
      <Btn kind="accent" small icon="spark">celebration</Btn>
      <span className="t-caption c-2">accent — streaks & iftar only</span>
    </div>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Inputs</SpecLabel>
    <Field label="City" value="Dhaka" icon="search"></Field>
    <div style={{ height: 12 }}></div>
    <Field label="Mosque name" placeholder="e.g. Masjid An-Noor" focus></Field>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Selection controls</SpecLabel>
    <div style={{ display: "flex", gap: 16, alignItems: "center", marginBottom: 12 }}>
      <Toggle on></Toggle><Toggle></Toggle><Toggle on disabled></Toggle>
      <Radio on></Radio><Radio></Radio>
      <CheckBox on></CheckBox><CheckBox></CheckBox>
      <Stepper val={3}></Stepper>
    </div>
    <SegControl opts={["Today", "Week", "Month", "Year"]} active={1}></SegControl>
    <div style={{ height: 12 }}></div>
    <div style={{ display: "flex", gap: 8 }}>
      <Chip active icon="check">Hanafi</Chip><Chip>Shafiʿi</Chip><Chip icon="pin">Dhaka</Chip>
    </div>
  </CBoard>
);

/* ---- sheet / dialog / nav ---- */
const SurfaceBoard = ({ dark }) => (
  <CBoard dark={dark}>
    <SpecLabel style={{ marginTop: 0, color: "var(--ink-3)" }}>Bottom sheet</SpecLabel>
    <div style={{ borderRadius: "24px 24px 0 0", background: "var(--surface)", boxShadow: "var(--e-2)", padding: "10px 20px 20px", border: "1px solid var(--line)" }}>
      <div style={{ width: 40, height: 4.5, borderRadius: 3, background: "var(--line)", margin: "0 auto 14px" }}></div>
      <div className="t-title" style={{ marginBottom: 4 }}>Calculation method</div>
      <div className="t-caption c-2" style={{ marginBottom: 12 }}>Suggested for Bangladesh</div>
      {[["University of Islamic Sciences, Karachi", true], ["Muslim World League", false], ["ISNA (North America)", false]].map(([t, on]) => (
        <div key={t} style={{ display: "flex", alignItems: "center", gap: 12, minHeight: 50 }}>
          <span className="t-body" style={{ flex: 1 }}>{t}</span><Radio on={on}></Radio>
        </div>
      ))}
    </div>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Dialog — confirm destructive-ish action</SpecLabel>
    <div style={{ borderRadius: "var(--r-lg)", background: "var(--surface)", boxShadow: "var(--e-2)", padding: 22, border: "1px solid var(--line)" }}>
      <div className="t-title" style={{ marginBottom: 6 }}>Reset count?</div>
      <div className="t-body c-2" style={{ marginBottom: 18 }}>Your session total (132) will be saved to history first.</div>
      <div style={{ display: "flex", gap: 10, justifyContent: "flex-end" }}>
        <Btn kind="ghost" small>Keep counting</Btn><Btn kind="primary" small>Save & reset</Btn>
      </div>
    </div>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Navigation bar — 5 destinations</SpecLabel>
    <div style={{ borderRadius: 18, overflow: "hidden", border: "1px solid var(--line)" }}>
      <BottomNav active={2} style={{ marginTop: 0 }}></BottomNav>
    </div>
  </CBoard>
);

/* ---- data view states ---- */
const StatesBoard = ({ dark }) => (
  <CBoard dark={dark}>
    <SpecLabel style={{ marginTop: 0, color: "var(--ink-3)" }}>Loading — skeleton, not spinner</SpecLabel>
    <div style={{ background: "var(--surface)", border: "1px solid var(--line)", borderRadius: 16, padding: 16 }}>
      <Skel w="38%" h={11}></Skel><Skel w="62%" h={26} style={{ margin: "10px 0" }}></Skel><Skel w="50%" h={11}></Skel>
    </div>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Empty — welcoming, never blank</SpecLabel>
    <div style={{ background: "var(--surface)", border: "1px solid var(--line)", borderRadius: 16, padding: 20, textAlign: "center" }}>
      <QalbMark size={44} color="var(--ink-3)" accent="var(--ink-3)"></QalbMark>
      <div className="t-title-sm" style={{ marginTop: 8 }}>Nothing here yet</div>
      <div className="t-caption c-2" style={{ marginTop: 3 }}>A gentle one-liner and a single clear action.</div>
      <div style={{ marginTop: 12 }}><Btn kind="tonal" small>Get started</Btn></div>
    </div>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Error — recoverable, calm</SpecLabel>
    <div style={{ background: "var(--surface)", border: "1px solid var(--line)", borderRadius: 16, padding: 18, display: "flex", gap: 12, alignItems: "center" }}>
      <QIcon name="info" size={22} color="var(--urgent)"></QIcon>
      <div style={{ flex: 1 }}>
        <div className="t-title-sm" style={{ fontSize: 14.5 }}>Compass sensor unavailable</div>
        <div className="t-caption c-2">Showing direction from map bearing instead.</div>
      </div>
      <Btn kind="ghost" small>Retry</Btn>
    </div>
    <SpecLabel style={{ color: "var(--ink-3)" }}>Permission denied — always a fallback path</SpecLabel>
    <div style={{ background: "var(--surface)", border: "1px solid var(--line)", borderRadius: 16, padding: 18 }}>
      <div className="t-title-sm" style={{ fontSize: 14.5 }}>Location is off</div>
      <div className="t-caption c-2" style={{ margin: "4px 0 12px" }}>No problem — pick your city and everything works offline.</div>
      <div style={{ display: "flex", gap: 8 }}><Btn kind="primary" small icon="search">Choose city</Btn><Btn kind="ghost" small>Open settings</Btn></div>
    </div>
    <SpecNote style={{ marginTop: 14, background: "var(--surface)", borderColor: "var(--line)", color: "var(--ink-2)" }}>
      Offline is the normal state — it is never an error. Only recitation-audio download and the future mosque finder may mention the network.</SpecNote>
  </CBoard>
);

const SecComponents = () => (
  <DCSection id="components" title="02 · Core component library" subtitle="Every interactive component: default / pressed / disabled / focused · every data view: loading / empty / error / permission-denied">
    <DCArtboard id="c-cd-l" label="Countdown card — 5 states · Light" width={420} height={950}><CountdownBoard></CountdownBoard></DCArtboard>
    <DCArtboard id="c-cd-d" label="Countdown card — 5 states · Dark" width={420} height={950}><CountdownBoard dark></CountdownBoard></DCArtboard>
    <DCArtboard id="c-pt" label="Prayer table row spec" width={420} height={820}><PrayerTableBoard></PrayerTableBoard></DCArtboard>
    <DCArtboard id="c-tr" label="Tracker item — 3 types × states" width={420} height={880}><TrackerBoard></TrackerBoard></DCArtboard>
    <DCArtboard id="c-hm" label="Heatmap cell & progress ring" width={420} height={620}><HeatBoard></HeatBoard></DCArtboard>
    <DCArtboard id="c-btn" label="Buttons · inputs · selection — Light" width={440} height={880}><ButtonBoard></ButtonBoard></DCArtboard>
    <DCArtboard id="c-btn-d" label="Buttons · inputs · selection — Dark" width={440} height={880}><ButtonBoard dark></ButtonBoard></DCArtboard>
    <DCArtboard id="c-surf" label="Sheets · dialogs · nav bar" width={420} height={900}><SurfaceBoard></SurfaceBoard></DCArtboard>
    <DCArtboard id="c-states" label="Data-view states pattern" width={420} height={900}><StatesBoard></StatesBoard></DCArtboard>
  </DCSection>
);

window.SecComponents = SecComponents;
