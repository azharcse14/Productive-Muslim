// productive_muslim/sec-home-qibla.jsx
/* global React, DCArtboard, DCSection, Phone, HomeBar, AppHeader, CountdownCard, PrayerTable, BottomNav, CompassDial,
   QIcon, QalbMark, Btn, Banner, Card, MotifBg, SpecNote */

const HQ_ROWS = (jamaatUnset) => [
  { name: "Fajr", time: "3:43 – 5:10 AM", jamaat: jamaatUnset ? null : "4:15", done: true },
  { name: "Sunrise", time: "5:10 AM", sunrise: true },
  { name: "Dhuhr", time: "12:00 – 4:38 PM", jamaat: jamaatUnset ? null : "1:30", done: true },
  { name: "Asr", time: "4:38 – 6:49 PM", jamaat: jamaatUnset ? null : "5:15" },
  { name: "Maghrib", time: "6:49 – 8:15 PM", jamaat: jamaatUnset ? null : "6:54" },
  { name: "Isha", time: "8:15 PM – 3:43 AM", jamaat: jamaatUnset ? null : "9:00" },
];

const SahriIftarRow = ({ ramadan, compact }) => (
  <div style={{ display: "flex", gap: 10, marginTop: compact ? 8 : 12 }}>
    {[["moon", "Sahri ends", "3:43 AM"], ["sun", "Iftar", "6:49 PM"]].map(([ic, t, v]) => (
      <div key={t} style={{ flex: 1, display: "flex", alignItems: "center", gap: 10, padding: compact ? "7px 12px" : "12px 14px",
        borderRadius: "var(--r-md)", background: ramadan ? "var(--accent-soft)" : "var(--surface)",
        border: "1px solid " + (ramadan ? "transparent" : "var(--line)"),
        color: ramadan ? "var(--on-accent-soft)" : "var(--ink)" }}>
        <QIcon name={ic} size={17} color={ramadan ? "var(--on-accent-soft)" : "var(--accent-strong)"}></QIcon>
        <span style={{ flex: 1 }}>
          <span className="t-caption" style={{ display: "block", opacity: 0.75, fontSize: 10.5 }}>{t}</span>
          <span className="t-label t-num" style={{ fontSize: compact ? 13 : 14.5 }}>{v}</span>
        </span>
      </div>
    ))}
  </div>
);

const HomeScreen = ({ dark, cd, jamaatUnset, ramadan, w = 390, h = 844, compact, tablet }) => {
  const c = cd || { state: "calm", eyebrow: "Asr · ends in", big: "2:41:09", sub: "Next: Maghrib at 6:49 PM · Jamaat 5:15 PM", pct: 0.35 };
  const pad = compact ? "0 16px" : "0 22px";
  const table = (
    <div style={{ marginTop: tablet ? 0 : compact ? 9 : 14 }}>
      <div style={{ display: "flex", alignItems: "baseline", padding: compact ? "0 4px 4px" : "0 4px 7px" }}>
        <span className="t-label c-2">Today’s prayers</span><span style={{ flex: 1 }}></span>
        <span className="t-caption c-3">jamaat · prayed</span>
      </div>
      <PrayerTable rows={HQ_ROWS(jamaatUnset)} activeIdx={3} dense={compact}></PrayerTable>
    </div>
  );
  return (
    <Phone dark={dark} w={w} h={h} time="4:55">
      <AppHeader city="Dhaka, Bangladesh"></AppHeader>
      <div style={{ flex: 1, padding: pad, paddingTop: compact ? 8 : 14, minHeight: 0, display: tablet ? "grid" : "block", gridTemplateColumns: tablet ? "1fr 1fr" : undefined, gap: tablet ? 18 : 0, alignContent: "start" }}>
        <div>
          <CountdownCard {...c} size={compact ? 36 : 56} style={compact ? { padding: "13px 18px 12px", borderRadius: "var(--r-lg)" } : undefined}></CountdownCard>
          <SahriIftarRow ramadan={ramadan} compact={compact}></SahriIftarRow>
        </div>
        {table}
        {jamaatUnset && !compact && !tablet && (
          <Banner icon="mosque" style={{ marginTop: 12 }}>Pray with congregation? Add your mosque’s jamaat times in My Mosque — the countdown will target them too.</Banner>
        )}
      </div>
      <BottomNav active={0}></BottomNav>
    </Phone>
  );
};

/* ---------- qibla ---------- */
const QiblaScreen = ({ dark, aligned, state }) => (
  <Phone dark={dark} time="5:02">
    <div style={{ display: "flex", alignItems: "center", padding: "6px 22px 0" }}>
      <QIcon name="back" size={22}></QIcon>
      <span className="t-title" style={{ flex: 1, textAlign: "center" }}>Qibla</span>
      <QIcon name="info" size={20} color="var(--ink-3)"></QIcon>
    </div>
    {state === "calibrate" ? (
      <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 36px", textAlign: "center" }}>
        <svg width="170" height="110" viewBox="0 0 170 110" fill="none">
          <path d="M48 55c0-22 18-38 37-38s37 16 37 38-18 38-37 38-37-16-37-38z" stroke="var(--line)" strokeWidth="3"></path>
          <path d="M85 17C66 17 48 33 48 55s18 38 37 38c10 0 19-4 26-11" stroke="var(--primary)" strokeWidth="4" strokeLinecap="round"></path>
          <path d="M105 88l8-8M105 88l-2-11" stroke="var(--primary)" strokeWidth="4" strokeLinecap="round"></path>
          <circle cx="42" cy="55" r="9" fill="var(--primary-soft)" stroke="var(--primary)" strokeWidth="2.5"></circle>
        </svg>
        <div className="t-title" style={{ marginTop: 24 }}>Calibrate your compass</div>
        <div className="t-body c-2" style={{ marginTop: 8 }}>Move your phone in a figure-8 a few times, away from metal objects and magnets.</div>
        <div style={{ marginTop: 20 }}><Btn kind="tonal" small>Skip — use map bearing</Btn></div>
      </div>
    ) : state === "nosensor" ? (
      <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 36px", textAlign: "center" }}>
        <QalbMark size={56} color="var(--ink-3)" accent="var(--ink-3)"></QalbMark>
        <div className="t-title" style={{ marginTop: 18 }}>No compass sensor</div>
        <div className="t-body c-2" style={{ marginTop: 8 }}>This device can’t sense direction. From Dhaka, the qibla is <b style={{ color: "var(--ink)" }}>278° — west, slightly north</b>. Face the setting sun and adjust a touch to the right.</div>
        <div className="t-caption c-3" style={{ marginTop: 14 }}>Kaaba is 4,973 km away</div>
      </div>
    ) : state === "noloc" ? (
      <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 36px", textAlign: "center" }}>
        <span style={{ width: 64, height: 64, borderRadius: 22, display: "grid", placeItems: "center", background: "var(--primary-soft)", color: "var(--on-primary-soft)" }}>
          <QIcon name="pin" size={30}></QIcon>
        </span>
        <div className="t-title" style={{ marginTop: 18 }}>Qibla needs your location</div>
        <div className="t-body c-2" style={{ marginTop: 8 }}>Direction to the Kaaba depends on where you stand. Use GPS once, or keep your chosen city — both work offline.</div>
        <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
          <Btn kind="primary" small icon="gps">Use GPS</Btn><Btn kind="tonal" small>Use Dhaka</Btn>
        </div>
      </div>
    ) : (
      <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div className="t-num" style={{ fontSize: 44, fontWeight: 700, letterSpacing: "-1px", color: aligned ? "var(--accent-strong)" : "var(--ink)" }}>
          {aligned ? "278°" : "242°"}
        </div>
        <div className="t-caption c-2" style={{ marginBottom: 18 }}>{aligned ? "Facing qibla · W by NW" : "Turn right to 278° · WSW"}</div>
        <CompassDial aligned={aligned} size={290}></CompassDial>
        <div style={{ marginTop: 22, minHeight: 48, display: "flex", alignItems: "center" }}>
          {aligned ? (
            <span style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "11px 20px", borderRadius: 99,
              background: "var(--accent-soft)", color: "var(--on-accent-soft)", fontWeight: 700, fontSize: 14.5 }}>
              <QIcon name="check" size={17} sw={2.6}></QIcon>You are facing the Kaaba
            </span>
          ) : (
            <span className="t-caption c-3">gentle haptic + gold ring when aligned (±3°)</span>
          )}
        </div>
        <div className="t-caption c-3" style={{ marginTop: 6 }}>Kaaba · 4,973 km from Dhaka</div>
      </div>
    )}
    <HomeBar></HomeBar>
  </Phone>
);

const SecHomeQibla = () => (
  <React.Fragment>
    <DCSection id="home" title="05 · Home — smart countdown" subtitle="One hero countdown that retargets: waqt start → jamaat → waqt end · Ramadan overrides for sahri & iftar · current waqt row highlighted">
      <DCArtboard id="h-calm" label="Calm · waqt remaining — Light" width={390} height={844}><HomeScreen></HomeScreen></DCArtboard>
      <DCArtboard id="h-dark" label="Calm — Dark" width={390} height={844}><HomeScreen dark></HomeScreen></DCArtboard>
      <DCArtboard id="h-amber" label="Jamaat ≤ 10 min · amber" width={390} height={844}>
        <HomeScreen cd={{ state: "amber", eyebrow: "Asr · jamaat in", big: "08:42", sub: "Jamaat 5:15 PM · Masjid An-Noor", pct: 0.82 }}></HomeScreen>
      </DCArtboard>
      <DCArtboard id="h-urgent" label="Makruh window · urgent — Dark" width={390} height={844}>
        <HomeScreen dark cd={{ state: "urgent", eyebrow: "Asr · ends in", big: "14:06", sub: "Maghrib begins 6:49 PM", pct: 0.94 }}></HomeScreen>
      </DCArtboard>
      <DCArtboard id="h-sahri" label="Ramadan · pre-Fajr “Sahri ends in” — Dark" width={390} height={844}>
        <HomeScreen dark ramadan cd={{ state: "sahri", eyebrow: "Sahri ends in", big: "42:18", sub: "Fajr 3:43 AM · Ramadan day 14", pct: 0.7 }}></HomeScreen>
      </DCArtboard>
      <DCArtboard id="h-iftar" label="Ramadan · “Iftar in” — Light" width={390} height={844}>
        <HomeScreen ramadan cd={{ state: "iftar", eyebrow: "Iftar in", big: "1:12:33", sub: "Maghrib 6:49 PM · may it be accepted", pct: 0.61 }}></HomeScreen>
      </DCArtboard>
      <DCArtboard id="h-nojamaat" label="Edge · jamaat not configured" width={390} height={844}><HomeScreen jamaatUnset></HomeScreen></DCArtboard>
      <DCArtboard id="h-small" label="Adapts · small 360×640" width={360} height={640}><HomeScreen compact w={360} h={640} cd={{ state: "calm", eyebrow: "Asr · ends in", big: "2:41:09", sub: "Next: Maghrib 6:49 PM", pct: 0.35 }}></HomeScreen></DCArtboard>
      <DCArtboard id="h-tablet" label="Adapts · tablet 768 — two columns" width={768} height={844}><HomeScreen tablet w={768} h={844}></HomeScreen></DCArtboard>
    </DCSection>
    <DCSection id="qibla" title="06 · Qibla compass" subtitle="Sensor-driven dial · subtle gold lock when aligned (haptic described, not loud) · every sensor/permission failure has a designed state">
      <DCArtboard id="q-main" label="Seeking · Light" width={390} height={844}><QiblaScreen></QiblaScreen></DCArtboard>
      <DCArtboard id="q-aligned" label="Aligned · gold lock — Dark" width={390} height={844}><QiblaScreen dark aligned></QiblaScreen></DCArtboard>
      <DCArtboard id="q-cal" label="Calibration prompt (figure-8)" width={390} height={844}><QiblaScreen state="calibrate"></QiblaScreen></DCArtboard>
      <DCArtboard id="q-nosensor" label="Sensor unavailable · fallback" width={390} height={844}><QiblaScreen dark state="nosensor"></QiblaScreen></DCArtboard>
      <DCArtboard id="q-noloc" label="Location needed" width={390} height={844}><QiblaScreen state="noloc"></QiblaScreen></DCArtboard>
    </DCSection>
  </React.Fragment>
);

window.SecHomeQibla = SecHomeQibla;
