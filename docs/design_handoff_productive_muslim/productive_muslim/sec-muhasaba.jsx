// productive_muslim/sec-muhasaba.jsx — the differentiator
/* global React, DCArtboard, DCSection, Phone, HomeBar, BottomNav, TrackerToggle, TrackerCount, TrackerDuration,
   Heatmap, ProgressRing, QIcon, QalbMark, Star8, MotifBg, Btn, Chip, Field, SegControl, Radio, Banner, Toggle, SpecNote, bnD, HEART_PATH */

const MhHeader = ({ title = "Muhasaba", sub, trail }) => (
  <div style={{ padding: "6px 22px 0", flexShrink: 0 }}>
    <div style={{ display: "flex", alignItems: "center" }}>
      <span className="t-headline">{title}</span><span style={{ flex: 1 }}></span>{trail}
    </div>
    {sub && <div className="t-caption c-2" style={{ marginTop: 2 }}>{sub}</div>}
  </div>
);

/* ---- daily entry ---- */
const DateSwitcher = ({ backfill }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 10, margin: "14px 0 4px" }}>
    <span style={{ width: 38, height: 38, borderRadius: 12, display: "grid", placeItems: "center", background: "var(--surface)", border: "1.5px solid var(--line)" }}><QIcon name="chevL" size={17}></QIcon></span>
    <div style={{ flex: 1, textAlign: "center" }}>
      <div className="t-title-sm">{backfill ? "Yesterday · Thu 11 Jun" : "Today · Fri 12 Jun"}</div>
      <div className="t-caption c-3">{backfill ? "Back-filling is welcome — honesty over streaks" : "26 Dhul-Ḥijjah 1447"}</div>
    </div>
    <span style={{ width: 38, height: 38, borderRadius: 12, display: "grid", placeItems: "center", background: "var(--surface)", border: "1.5px solid var(--line)", opacity: backfill ? 1 : 0.35 }}><QIcon name="chevR" size={17}></QIcon></span>
  </div>
);

const MhEntry = ({ dark, backfill }) => (
  <Phone dark={dark} time="9:12">
    <MhHeader sub="Take account of yourself, gently." trail={<QIcon name="trend" size={21} color="var(--ink-2)"></QIcon>}></MhHeader>
    <div style={{ flex: 1, padding: "0 22px", minHeight: 0, overflow: "hidden" }}>
      <DateSwitcher backfill={backfill}></DateSwitcher>
      <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 2px 10px" }}>
        <ProgressRing pct={backfill ? 0.9 : 0.55} size={52} sw={6}>
          <span className="t-label t-num" style={{ fontSize: 11 }}>{backfill ? "90%" : "55%"}</span>
        </ProgressRing>
        <span className="t-caption c-2" style={{ flex: 1 }}>{backfill ? "A strong day, mashallah." : "6 of 11 so far — the day isn’t over."}</span>
      </div>
      <div className="t-overline c-3" style={{ fontSize: 10, margin: "4px 0 8px" }}>Salah</div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 7 }}>
        {[["Fajr", 1], ["Dhuhr", 1], ["Asr", 1], ["Maghrib", 0], ["Isha", 0]].map(([p, on]) => (
          <div key={p} style={{ textAlign: "center", padding: "10px 2px 8px", borderRadius: 13, minHeight: 60,
            background: on ? "var(--primary)" : "var(--surface)",
            border: on ? "1.5px solid var(--primary)" : "1.5px solid var(--line)",
            color: on ? "var(--on-primary)" : "var(--ink-2)" }}>
            <QIcon name={on ? "check" : "clock"} size={16} sw={on ? 2.6 : 1.7}></QIcon>
            <div style={{ fontSize: 10.5, fontWeight: 700, marginTop: 3 }}>{p}</div>
          </div>
        ))}
      </div>
      <div className="t-overline c-3" style={{ fontSize: 10, margin: "14px 0 8px" }}>Daily deeds</div>
      <TrackerToggle icon="book" label="Read Quran" sub="Any amount counts" on></TrackerToggle>
      <div style={{ height: 8 }}></div>
      <TrackerCount icon="beads" label="Azkar sessions" sub="Target 3" val={2}></TrackerCount>
      <div style={{ height: 8 }}></div>
      <TrackerDuration icon="clock" label="Hadith study" sub="Target 15 min" val={backfill ? "20 min" : null} placeholder="0 min"></TrackerDuration>
      <div style={{ height: 8 }}></div>
      <TrackerToggle icon="heart" label="Sadaqah" sub="Even a smile counts"></TrackerToggle>
      <div style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 12, color: "var(--primary)" }}>
        <QIcon name="plus" size={16}></QIcon><span className="t-label">Add your own item</span>
      </div>
    </div>
    <BottomNav active={2}></BottomNav>
  </Phone>
);

/* ---- custom field creation ---- */
const MhCustomField = ({ dark, archive }) => (
  <Phone dark={dark} time="9:15">
    <div style={{ display: "flex", alignItems: "center", padding: "6px 22px 0" }}>
      <QIcon name="close" size={22}></QIcon>
      <span className="t-title-sm" style={{ flex: 1, textAlign: "center" }}>{archive ? "Edit item" : "New muhasaba item"}</span>
      <span className="t-label" style={{ color: "var(--primary)" }}>Save</span>
    </div>
    <div style={{ flex: 1, padding: "20px 22px 0" }}>
      <Field label="Name" value="Istighfar" focus={!archive}></Field>
      <div className="t-label c-2" style={{ margin: "18px 0 8px" }}>Type</div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
        {[["check", "Yes / no", false], ["plus", "Count", true], ["clock", "Duration", false]].map(([ic, t, on]) => (
          <div key={t} style={{ textAlign: "center", padding: "14px 6px", borderRadius: "var(--r-md)",
            background: "var(--surface)", border: on ? "2px solid var(--primary)" : "1.5px solid var(--line)" }}>
            <QIcon name={ic} size={19} color={on ? "var(--primary)" : "var(--ink-3)"}></QIcon>
            <div className="t-label" style={{ marginTop: 5, fontSize: 12, color: on ? "var(--primary)" : "var(--ink-2)" }}>{t}</div>
          </div>
        ))}
      </div>
      <div className="t-label c-2" style={{ margin: "18px 0 8px" }}>Daily target <span className="c-3" style={{ fontWeight: 500 }}>· optional</span></div>
      <window.Stepper val={100}></window.Stepper>
      <div className="t-label c-2" style={{ margin: "18px 0 8px" }}>Icon & color — curated set</div>
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        {["beads", "heart", "book", "spark", "moon", "sun", "food", "globe"].map((ic, i) => (
          <span key={ic} style={{ width: 42, height: 42, borderRadius: 13, display: "grid", placeItems: "center",
            background: i === 3 ? "var(--primary)" : "var(--surface)", color: i === 3 ? "var(--on-primary)" : "var(--ink-2)",
            border: i === 3 ? "none" : "1.5px solid var(--line)" }}><QIcon name={ic} size={19}></QIcon></span>
        ))}
      </div>
      <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
        {["#15564D", "#C08A2E", "#5B7DB1", "#8A5BA6", "#A9573B"].map((c, i) => (
          <span key={c} style={{ width: 30, height: 30, borderRadius: 99, background: c, border: i === 0 ? "3px solid var(--accent)" : "2px solid var(--line)" }}></span>
        ))}
      </div>
      {archive && (
        <div style={{ marginTop: 24, padding: 16, borderRadius: "var(--r-md)", background: "var(--surface)", border: "1.5px solid var(--line)" }}>
          <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
            <QIcon name="archive" size={19} color="var(--ink-2)"></QIcon>
            <span className="t-title-sm" style={{ flex: 1, fontSize: 14.5 }}>Archive this item</span>
            <Btn kind="tonal" small>Archive</Btn>
          </div>
          <div className="t-caption c-2" style={{ marginTop: 8 }}>
            Archiving hides it from your daily list. <b>All history is preserved</b> in your dashboard, and you can restore it anytime. Nothing in Productive Muslim is ever “failed” or erased.
          </div>
        </div>
      )}
    </div>
    <HomeBar style={{ marginTop: "auto" }}></HomeBar>
  </Phone>
);

/* ---- dashboard ---- */
const mhWeeks = [
  [-1, -1, 1, 2, 3, 2, 4], [3, 4, 2, 1, 0, 2, 3], [4, 4, 3, 2, 3, 4, 4], [2, 3, 4, 4, 3, 2, 1], [0, 2, 3, 4, -1, -1, -1],
];
const BarRow = ({ icon, label, pct, val }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 11 }}>
    <QIcon name={icon} size={16} color="var(--ink-2)" style={{ flexShrink: 0 }}></QIcon>
    <span className="t-caption" style={{ width: 88, fontWeight: 600 }}>{label}</span>
    <div style={{ flex: 1, height: 8, borderRadius: 5, background: "var(--surface-2)" }}>
      <div style={{ width: pct, height: "100%", borderRadius: 5, background: "var(--primary)" }}></div>
    </div>
    <span className="t-caption t-num c-2" style={{ width: 38, textAlign: "end" }}>{val}</span>
  </div>
);
const MhDashboard = ({ dark, range }) => (
  <Phone dark={dark} time="9:30">
    <MhHeader title="Dashboard" trail={<QIcon name="share" size={20} color="var(--ink-2)"></QIcon>}></MhHeader>
    <div style={{ flex: 1, padding: "12px 22px 0", minHeight: 0, overflow: "hidden" }}>
      <SegControl opts={["Today", "Week", "Month", "Year", "Custom"]} active={range === "custom" ? 4 : 2}></SegControl>
      {range === "custom" && (
        <div style={{ display: "flex", gap: 8, marginTop: 10, alignItems: "center" }}>
          <Chip icon="cal">1 Ramadan</Chip><span className="t-caption c-3">→</span><Chip icon="cal">29 Ramadan</Chip>
        </div>
      )}
      <div style={{ display: "flex", gap: 12, alignItems: "center", marginTop: 14, padding: 16, borderRadius: "var(--r-lg)", background: "var(--surface)", border: "1px solid var(--line)" }}>
        <ProgressRing pct={0.81} size={92} sw={9}>
          <div className="t-headline t-num" style={{ fontSize: 23 }}>81%</div>
        </ProgressRing>
        <div style={{ flex: 1 }}>
          <div className="t-title-sm">Better than last month</div>
          <div className="t-caption c-2" style={{ marginTop: 3 }}>+9% vs May · your strongest area: salah</div>
          <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 8, color: "var(--accent-strong)" }}>
            <QIcon name="spark" size={15}></QIcon><span className="t-caption" style={{ fontWeight: 700 }}>12-day Fajr streak — mashallah</span>
          </div>
        </div>
      </div>
      <div className="t-label c-2" style={{ margin: "16px 0 8px" }}>June at a glance</div>
      <div style={{ padding: 14, borderRadius: "var(--r-lg)", background: "var(--surface)", border: "1px solid var(--line)" }}>
        <Heatmap data={mhWeeks} cell={15} gap={4}></Heatmap>
        <div style={{ display: "flex", alignItems: "center", gap: 5, marginTop: 10 }}>
          <span className="t-caption c-3" style={{ fontSize: 10 }}>less</span>
          {window.HM_LEVELS.map((c, i) => <span key={i} style={{ width: 10, height: 10, borderRadius: 3, background: c }}></span>)}
          <span className="t-caption c-3" style={{ fontSize: 10 }}>more</span>
          <span style={{ flex: 1 }}></span>
          <span className="t-caption c-3" style={{ fontSize: 10 }}>quiet days are rest, not failure</span>
        </div>
      </div>
      <div className="t-label c-2" style={{ margin: "16px 0 10px" }}>By item</div>
      <BarRow icon="mosque" label="5 prayers" pct="92%" val="92%"></BarRow>
      <BarRow icon="book" label="Quran" pct="74%" val="74%"></BarRow>
      <BarRow icon="beads" label="Azkar" pct="66%" val="66%"></BarRow>
      <BarRow icon="moon" label="Tahajjud" pct="31%" val="31%"></BarRow>
    </div>
    <BottomNav active={2}></BottomNav>
  </Phone>
);

/* ---- empty states ---- */
const MhEmpty = ({ dark, kind }) => (
  <Phone dark={dark} time="9:12">
    <MhHeader title={kind === "range" ? "Dashboard" : "Muhasaba"}></MhHeader>
    <div style={{ flex: 1, padding: "0 30px", display: "flex", flexDirection: "column", justifyContent: "center", textAlign: "center" }}>
      {kind === "range" ? (
        <React.Fragment>
          <QIcon name="cal" size={40} color="var(--ink-3)" style={{ margin: "0 auto" }}></QIcon>
          <div className="t-title" style={{ marginTop: 14 }}>Nothing recorded in this range</div>
          <div className="t-body c-2" style={{ marginTop: 8 }}>You started Productive Muslim on 2 June — try a range after that, or widen to “Year”.</div>
          <div style={{ marginTop: 18 }}><Btn kind="tonal" small>Jump to my first week</Btn></div>
        </React.Fragment>
      ) : (
        <React.Fragment>
          <QalbMark size={72} color="var(--primary)" accent="var(--accent)"></QalbMark>
          <div className="t-headline" style={{ marginTop: 18 }}>Your first muhasaba</div>
          <div className="t-body c-2" style={{ marginTop: 10, textAlign: "start" }}>
            Muhasaba is the old practice of taking account of one’s own day — quietly, honestly, before Allah.
            Check off what you did. Skip what you didn’t. <b style={{ color: "var(--ink)" }}>There are no red marks here</b> — only a record that helps you grow.
          </div>
          <div style={{ marginTop: 20 }}><Btn kind="primary" full>Begin with today</Btn></div>
        </React.Fragment>
      )}
    </div>
    <BottomNav active={2}></BottomNav>
  </Phone>
);

/* ---- lock screen ---- */
const MhLock = ({ dark }) => (
  <Phone dark={dark} time="9:12">
    <MhHeader title="Muhasaba"></MhHeader>
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 36px", textAlign: "center" }}>
      <span style={{ width: 64, height: 64, borderRadius: 22, display: "grid", placeItems: "center", background: "var(--primary-soft)", color: "var(--on-primary-soft)" }}>
        <QIcon name="lock" size={28}></QIcon>
      </span>
      <div className="t-title" style={{ marginTop: 16 }}>This space is yours alone</div>
      <div className="t-caption c-2" style={{ marginTop: 6 }}>Unlock with your PIN or fingerprint</div>
      <div style={{ display: "flex", gap: 12, margin: "22px 0 26px" }}>
        {[1, 1, 0, 0].map((f, i) => (
          <span key={i} style={{ width: 14, height: 14, borderRadius: 99, background: f ? "var(--primary)" : "transparent", border: "2px solid " + (f ? "var(--primary)" : "var(--ink-3)") }}></span>
        ))}
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 64px)", gap: 12, justifyContent: "center" }}>
        {[1, 2, 3, 4, 5, 6, 7, 8, 9, "", 0, "fp"].map((k, i) => (
          <span key={i} style={{ height: 64, borderRadius: 99, display: "grid", placeItems: "center",
            background: k === "" ? "transparent" : "var(--surface)", border: k === "" ? "none" : "1px solid var(--line)",
            fontSize: 21, fontWeight: 600 }}>
            {k === "fp" ? <QIcon name="fingerprint" size={26} color="var(--primary)"></QIcon> : k}
          </span>
        ))}
      </div>
    </div>
    <HomeBar></HomeBar>
  </Phone>
);

/* ---- share card (exportable image, 4:5) ---- */
const MhShareCard = () => (
  <div className="q-light" style={{ width: 420, height: 525, background: "var(--primary)", color: "var(--on-primary)", position: "relative", overflow: "hidden", fontFamily: "var(--font-ui)", borderRadius: 18, display: "flex", flexDirection: "column", padding: 30 }}>
    <MotifBg opacity={0.08} cell={110}></MotifBg>
    <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 10 }}>
      <QalbMark size={34} color="var(--on-primary)" accent="var(--accent)" sw={3.2}></QalbMark>
      <span className="t-title-sm">Productive Muslim</span>
      <span style={{ flex: 1 }}></span>
      <span className="t-caption" style={{ opacity: 0.75 }}>Ramadan 1447</span>
    </div>
    <div style={{ position: "relative", flex: 1, display: "flex", flexDirection: "column", justifyContent: "center" }}>
      <div className="t-overline" style={{ opacity: 0.7 }}>My Ramadan, alhamdulillah</div>
      <div style={{ fontSize: 64, fontWeight: 700, letterSpacing: "-2px", lineHeight: 1.05, marginTop: 8 }}>29 <span style={{ fontSize: 26, fontWeight: 600, opacity: 0.8 }}>days fasted</span></div>
      <div style={{ display: "flex", gap: 26, marginTop: 22 }}>
        {[["152", "prayers in jamaat"], ["18", "juz read"], ["94%", "muhasaba"]].map(([v, l]) => (
          <div key={l}>
            <div className="t-num" style={{ fontSize: 27, fontWeight: 700, color: "var(--accent)" }}>{v}</div>
            <div className="t-caption" style={{ opacity: 0.75, marginTop: 2 }}>{l}</div>
          </div>
        ))}
      </div>
    </div>
    <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 8, opacity: 0.85 }}>
      <span className="t-caption">May it be accepted · تقبل الله</span>
    </div>
  </div>
);

const SecMuhasaba = () => (
  <DCSection id="muhasaba" title="09 · Muhasaba — the differentiator" subtitle="Daily self-accounting · three input types · positive framing is a hard rule: no red, no “failed”, no shame states">
    <DCArtboard id="m-entry" label="Daily entry · Light" width={390} height={844}><MhEntry></MhEntry></DCArtboard>
    <DCArtboard id="m-entry-d" label="Daily entry · Dark" width={390} height={844}><MhEntry dark></MhEntry></DCArtboard>
    <DCArtboard id="m-backfill" label="Back-filling yesterday" width={390} height={844}><MhEntry backfill></MhEntry></DCArtboard>
    <DCArtboard id="m-custom" label="Custom item · create" width={390} height={844}><MhCustomField></MhCustomField></DCArtboard>
    <DCArtboard id="m-archive" label="Edit + archive (history preserved)" width={390} height={844}><MhCustomField archive dark></MhCustomField></DCArtboard>
    <DCArtboard id="m-dash" label="Dashboard · month — Light" width={390} height={844}><MhDashboard></MhDashboard></DCArtboard>
    <DCArtboard id="m-dash-d" label="Dashboard — Dark" width={390} height={844}><MhDashboard dark></MhDashboard></DCArtboard>
    <DCArtboard id="m-dash-c" label="Dashboard · custom range (Ramadan)" width={390} height={844}><MhDashboard range="custom"></MhDashboard></DCArtboard>
    <DCArtboard id="m-empty1" label="Empty · first day welcome" width={390} height={844}><MhEmpty></MhEmpty></DCArtboard>
    <DCArtboard id="m-empty2" label="Empty · no data in range" width={390} height={844}><MhEmpty kind="range" dark></MhEmpty></DCArtboard>
    <DCArtboard id="m-lock" label="Privacy · PIN + biometric lock" width={390} height={844}><MhLock></MhLock></DCArtboard>
    <DCArtboard id="m-lock-d" label="Lock — Dark" width={390} height={844}><MhLock dark></MhLock></DCArtboard>
    <DCArtboard id="m-share" label="Share card · Ramadan summary (4:5 export)" width={420} height={525}><MhShareCard></MhShareCard></DCArtboard>
  </DCSection>
);

window.SecMuhasaba = SecMuhasaba;
