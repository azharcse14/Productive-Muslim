// productive_muslim/sec-misc.jsx — Ramadan · My Mosque · Settings · Calendar
/* global React, DCArtboard, DCSection, Phone, HomeBar, BottomNav, CountdownCard, QIcon, QalbMark, MotifBg, Btn, Chip,
   Field, SegControl, Radio, Toggle, Banner, ListRow, Stepper, SpecNote, bnD */

const MiscHead = ({ title, back = true, trail }) => (
  <div style={{ display: "flex", alignItems: "center", padding: "6px 22px 0", flexShrink: 0 }}>
    {back ? <QIcon name="back" size={22}></QIcon> : <span style={{ width: 22 }}></span>}
    <span className="t-title" style={{ flex: 1, textAlign: "center" }}>{title}</span>
    {trail || <span style={{ width: 22 }}></span>}
  </div>
);

/* ============ RAMADAN ============ */
const RamadanHome = ({ dark }) => (
  <Phone dark={dark} time="4:32">
    <MiscHead title="Ramadan 1447" trail={<QIcon name="cal" size={20} color="var(--ink-2)"></QIcon>}></MiscHead>
    <div style={{ flex: 1, padding: "14px 22px 0", minHeight: 0, overflow: "hidden" }}>
      <div style={{ borderRadius: "var(--r-xl)", padding: 20, background: "var(--primary)", color: "var(--on-primary)", position: "relative", overflow: "hidden" }}>
        <MotifBg opacity={0.07} cell={100}></MotifBg>
        <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{ flex: 1 }}>
            <div className="t-overline" style={{ opacity: 0.75 }}>Roza counter</div>
            <div style={{ fontSize: 44, fontWeight: 700, letterSpacing: "-1.5px", lineHeight: 1.1, marginTop: 4 }}>Day 14 <span style={{ fontSize: 18, fontWeight: 600, opacity: 0.75 }}>of 30</span></div>
            <div className="t-caption" style={{ opacity: 0.8, marginTop: 4 }}>16 days remain · may they be light</div>
          </div>
          <QalbMark size={56} color="var(--on-primary)" accent="var(--accent)" sw={3}></QalbMark>
        </div>
      </div>
      <div style={{ display: "flex", gap: 10, marginTop: 12 }}>
        <CountdownCard state="sahri" eyebrow="Sahri ends in" big="42:18" sub="Fajr 3:43 AM" pct={0.7} style={{ flex: 1, padding: "16px 16px 14px" }}></CountdownCard>
        <CountdownCard state="iftar" eyebrow="Iftar in" big="14:09:51" sub="Maghrib 6:49 PM" pct={0.12} style={{ flex: 1, padding: "16px 16px 14px" }}></CountdownCard>
      </div>
      <div style={{ display: "flex", alignItems: "baseline", margin: "16px 0 8px" }}>
        <span className="t-label c-2">This month</span><span style={{ flex: 1 }}></span><span className="t-caption" style={{ color: "var(--primary)", fontWeight: 700 }}>Full table</span>
      </div>
      <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)", overflow: "hidden" }}>
        <div style={{ display: "flex", padding: "9px 16px", borderBottom: "1px solid var(--line)" }} className="t-caption c-3">
          <span style={{ width: 70 }}>Ramadan</span><span style={{ flex: 1 }}>Date</span><span style={{ width: 64, textAlign: "center" }}>Sahri</span><span style={{ width: 64, textAlign: "end" }}>Iftar</span>
        </div>
        {[["13", "Thu 11 Jun", "3:43", "6:48", false], ["14", "Fri 12 Jun", "3:43", "6:49", true], ["15", "Sat 13 Jun", "3:43", "6:49", false], ["16", "Sun 14 Jun", "3:44", "6:49", false]].map(([d, g, s, i, on]) => (
          <div key={d} className="t-caption t-num" style={{ display: "flex", padding: "10px 16px", fontSize: 12.5,
            background: on ? "var(--primary-soft)" : "transparent", color: on ? "var(--on-primary-soft)" : "var(--ink)", fontWeight: on ? 700 : 500 }}>
            <span style={{ width: 70 }}>{d}</span><span style={{ flex: 1 }}>{g}</span><span style={{ width: 64, textAlign: "center" }}>{s} AM</span><span style={{ width: 64, textAlign: "end" }}>{i} PM</span>
          </div>
        ))}
      </div>
      <div style={{ display: "flex", gap: 10, marginTop: 12 }}>
        {[["Zakat calculator", "2.5% made simple"], ["Fitra", "৳ 115 / person · 1447"]].map(([t, s]) => (
          <div key={t} style={{ flex: 1, padding: 14, borderRadius: "var(--r-md)", background: "var(--surface)", border: "1px solid var(--line)" }}>
            <div className="t-title-sm" style={{ fontSize: 14 }}>{t}</div>
            <div className="t-caption c-2" style={{ marginTop: 2 }}>{s}</div>
          </div>
        ))}
      </div>
    </div>
    <BottomNav active={4}></BottomNav>
  </Phone>
);

const ZakatCalc = ({ dark, result }) => (
  <Phone dark={dark} time="2:10">
    <MiscHead title="Zakat calculator"></MiscHead>
    <div style={{ flex: 1, padding: "18px 22px 0" }}>
      {!result ? (
        <React.Fragment>
          <Banner icon="info" style={{ marginBottom: 16 }}>Calculated locally on your phone. Nisab today ≈ ৳ 1,12,400 (87.48 g gold standard).</Banner>
          <Field label="Cash & bank balance" value="৳ 4,20,000" focus></Field>
          <div style={{ height: 12 }}></div>
          <Field label="Gold & silver (market value)" value="৳ 1,80,000"></Field>
          <div style={{ height: 12 }}></div>
          <Field label="Business assets & investments" value="৳ 2,50,000"></Field>
          <div style={{ height: 12 }}></div>
          <Field label="Debts you owe (deducted)" value="৳ 60,000"></Field>
          <div style={{ marginTop: 20 }}><Btn kind="primary" full>Calculate zakat</Btn></div>
        </React.Fragment>
      ) : (
        <React.Fragment>
          <div style={{ borderRadius: "var(--r-xl)", padding: 24, background: "var(--primary)", color: "var(--on-primary)", position: "relative", overflow: "hidden", textAlign: "center" }}>
            <MotifBg opacity={0.07} cell={90}></MotifBg>
            <div style={{ position: "relative" }}>
              <div className="t-overline" style={{ opacity: 0.75 }}>Your zakat · 2.5%</div>
              <div className="t-num" style={{ fontSize: 46, fontWeight: 700, letterSpacing: "-1px", margin: "8px 0 4px" }}>৳ 19,750</div>
              <div className="t-caption" style={{ opacity: 0.8 }}>on zakatable wealth of ৳ 7,90,000</div>
            </div>
          </div>
          <div style={{ background: "var(--surface)", border: "1px solid var(--line)", borderRadius: "var(--r-lg)", marginTop: 14, padding: "4px 16px" }}>
            {[["Cash & bank", "৳ 4,20,000"], ["Gold & silver", "৳ 1,80,000"], ["Business assets", "৳ 2,50,000"], ["Less: debts", "− ৳ 60,000"]].map(([t, v]) => (
              <div key={t} style={{ display: "flex", padding: "11px 0", borderBottom: "1px solid var(--line)" }} className="t-caption">
                <span className="c-2">{t}</span><span style={{ flex: 1 }}></span><span className="t-num" style={{ fontWeight: 600 }}>{v}</span>
              </div>
            ))}
            <div style={{ display: "flex", padding: "11px 0" }} className="t-label">
              <span>Above nisab ✓ — zakat is due</span>
            </div>
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
            <Btn kind="tonal" small icon="share">Share</Btn><Btn kind="ghost" small icon="reset">Recalculate</Btn>
          </div>
        </React.Fragment>
      )}
    </div>
    <HomeBar style={{ marginTop: "auto" }}></HomeBar>
  </Phone>
);

/* ============ MY MOSQUE ============ */
const JamaatRow = ({ p, mode, val, last }) => (
  <div style={{ padding: "12px 16px", borderBottom: last ? "none" : "1px solid var(--line)" }}>
    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
      <span className="t-title-sm" style={{ width: 76, fontSize: 14.5 }}>{p}</span>
      <div style={{ flex: 1, display: "flex", gap: 4, padding: 3, background: "var(--surface-2)", borderRadius: 10 }}>
        {["Fixed time", "Offset"].map((m, i) => (
          <span key={m} className="t-caption" style={{ flex: 1, textAlign: "center", padding: "6px 4px", borderRadius: 8, fontWeight: 600, fontSize: 11,
            background: (mode === "fixed" ? i === 0 : i === 1) ? "var(--surface)" : "transparent",
            color: (mode === "fixed" ? i === 0 : i === 1) ? "var(--ink)" : "var(--ink-3)",
            boxShadow: (mode === "fixed" ? i === 0 : i === 1) ? "var(--e-1)" : "none" }}>{m}</span>
        ))}
      </div>
      <span className="t-label t-num" style={{ width: 78, textAlign: "end", color: "var(--primary)" }}>{val}</span>
    </div>
  </div>
);
const MyMosque = ({ dark, seasonal }) => (
  <Phone dark={dark} time="6:02">
    <MiscHead title="My Mosque" trail={<QIcon name="plus" size={21} color="var(--primary)"></QIcon>}></MiscHead>
    <div style={{ flex: 1, padding: "14px 22px 0", minHeight: 0, overflow: "hidden" }}>
      <div style={{ display: "flex", gap: 8 }}>
        <Chip active icon="home">Masjid An-Noor · home</Chip><Chip icon="pin">Baitul Falah · work</Chip>
      </div>
      <Field label="Mosque name" value="Masjid An-Noor" style={{ marginTop: 14 }}></Field>
      <div className="t-label c-2" style={{ margin: "16px 0 8px" }}>Jamaat times — each prayer chooses fixed or offset</div>
      <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)" }}>
        <JamaatRow p="Fajr" mode="fixed" val="4:15 AM"></JamaatRow>
        <JamaatRow p="Dhuhr" mode="fixed" val="1:30 PM"></JamaatRow>
        <JamaatRow p="Asr" mode="fixed" val="5:15 PM"></JamaatRow>
        <JamaatRow p="Maghrib" mode="offset" val="waqt + 5 min"></JamaatRow>
        <JamaatRow p="Isha" mode="fixed" val="9:00 PM" last></JamaatRow>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginTop: 14, padding: "12px 16px", background: "var(--surface)", borderRadius: "var(--r-md)", border: "1px solid var(--line)" }}>
        <QIcon name="bell" size={19} color="var(--ink-2)"></QIcon>
        <span style={{ flex: 1 }}>
          <span className="t-title-sm" style={{ display: "block", fontSize: 14.5 }}>Jamaat reminder</span>
          <span className="t-caption c-2">10 minutes before · tap to change</span>
        </span>
        <Toggle on></Toggle>
      </div>
      {seasonal && (
        <div style={{ marginTop: 14, padding: 16, borderRadius: "var(--r-md)", background: "var(--surface)", border: "1.5px dashed var(--line)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <QIcon name="sun" size={18} color="var(--accent-strong)"></QIcon>
            <span className="t-title-sm" style={{ flex: 1, fontSize: 14.5 }}>Seasonal profile <span className="t-caption c-3">· advanced</span></span>
            <Toggle on></Toggle>
          </div>
          <div className="t-caption c-2" style={{ marginTop: 8 }}>Summer (Apr–Sep): Isha 9:00 PM · Winter (Oct–Mar): Isha 7:30 PM. Switches automatically on 1 April / 1 October.</div>
        </div>
      )}
    </div>
    <HomeBar style={{ marginTop: "auto" }}></HomeBar>
  </Phone>
);

/* ============ SETTINGS ============ */
const SetRow = ({ icon, t, v, toggle, on, last }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 12, minHeight: 52, padding: "0 16px", borderBottom: last ? "none" : "1px solid var(--line)" }}>
    <QIcon name={icon} size={18} color="var(--ink-2)" style={{ flexShrink: 0 }}></QIcon>
    <span className="t-body" style={{ flex: 1, fontSize: 14.5, fontWeight: 500 }}>{t}</span>
    {toggle ? <Toggle on={on}></Toggle> : (
      <React.Fragment>
        {v && <span className="t-caption c-2">{v}</span>}
        <QIcon name="chevR" size={15} color="var(--ink-3)"></QIcon>
      </React.Fragment>
    )}
  </div>
);
const SetGroup = ({ label, children }) => (
  <React.Fragment>
    <div className="t-overline c-3" style={{ fontSize: 10, margin: "16px 2px 7px" }}>{label}</div>
    <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)", overflow: "hidden" }}>{children}</div>
  </React.Fragment>
);
const SettingsScreen = ({ dark }) => (
  <Phone dark={dark} time="8:44">
    <MiscHead title="Settings" back={false}></MiscHead>
    <div style={{ flex: 1, padding: "0 22px", minHeight: 0, overflow: "hidden" }}>
      <SetGroup label="Prayer calculation">
        <SetRow icon="pin" t="Location" v="Dhaka · GPS"></SetRow>
        <SetRow icon="book" t="Asr madhab" v="Hanafi"></SetRow>
        <SetRow icon="globe" t="Calculation method" v="Karachi"></SetRow>
        <SetRow icon="gear" t="Minute adjustments" v="Fajr +2"></SetRow>
        <SetRow icon="moon" t="High-latitude rule" v="Advanced" last></SetRow>
      </SetGroup>
      <SetGroup label="Notifications">
        <SetRow icon="bell" t="Azan & alerts matrix" v="Custom"></SetRow>
        <SetRow icon="mosque" t="Jamaat reminder" toggle on></SetRow>
        <SetRow icon="heart" t="Evening muhasaba nudge" toggle on last></SetRow>
      </SetGroup>
      <SetGroup label="Appearance & language">
        <SetRow icon="sun" t="Theme" v="System"></SetRow>
        <SetRow icon="globe" t="Language" v="English"></SetRow>
        <SetRow icon="book" t="Quran font size" v="27pt" last></SetRow>
      </SetGroup>
      <SetGroup label="Privacy & app">
        <SetRow icon="lock" t="App lock" v="Muhasaba only"></SetRow>
        <SetRow icon="reset" t="Run setup again"></SetRow>
        <SetRow icon="info" t="About & translation credits" last></SetRow>
      </SetGroup>
    </div>
    <BottomNav active={4}></BottomNav>
  </Phone>
);

const NotifMatrix = ({ dark }) => (
  <Phone dark={dark} time="8:45">
    <MiscHead title="Azan & alerts"></MiscHead>
    <div style={{ flex: 1, padding: "14px 22px 0" }}>
      <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)", overflow: "hidden" }}>
        <div style={{ display: "flex", padding: "10px 16px", borderBottom: "1px solid var(--line)" }} className="t-caption c-3">
          <span style={{ width: 74 }}>Prayer</span><span style={{ flex: 1, textAlign: "center" }}>Azan</span><span style={{ flex: 1, textAlign: "center" }}>Beep</span><span style={{ flex: 1, textAlign: "center" }}>Silent</span><span style={{ flex: 1, textAlign: "center" }}>Off</span>
        </div>
        {[["Fajr", 0], ["Dhuhr", 2], ["Asr", 1], ["Maghrib", 0], ["Isha", 0]].map(([p, sel], r, arr) => (
          <div key={p} style={{ display: "flex", alignItems: "center", padding: "11px 16px", borderBottom: r === arr.length - 1 ? "none" : "1px solid var(--line)" }}>
            <span className="t-title-sm" style={{ width: 74, fontSize: 14 }}>{p}</span>
            {[0, 1, 2, 3].map((c) => (
              <span key={c} style={{ flex: 1, display: "grid", placeItems: "center" }}><Radio on={c === sel}></Radio></span>
            ))}
          </div>
        ))}
      </div>
      <SetGroup label="Ramadan & extras">
        <SetRow icon="moon" t="Sahri warning · 30 min before" toggle on></SetRow>
        <SetRow icon="sun" t="Iftar moment alert" toggle on></SetRow>
        <SetRow icon="spark" t="Streak milestones" toggle last></SetRow>
      </SetGroup>
      <Banner icon="info" style={{ marginTop: 14 }}>Azan sound plays even in silent mode if your system allows alarms — configurable per prayer.</Banner>
    </div>
    <HomeBar style={{ marginTop: "auto" }}></HomeBar>
  </Phone>
);

const MinuteAdjust = ({ dark }) => (
  <Phone dark={dark} time="8:46">
    <MiscHead title="Minute adjustments"></MiscHead>
    <div style={{ flex: 1, padding: "14px 22px 0" }}>
      <Banner icon="info" style={{ marginBottom: 14 }}>Fine-tune each prayer if your local mosque’s timetable differs slightly from the calculation.</Banner>
      <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)" }}>
        {[["Fajr", "+2"], ["Sunrise", "0"], ["Dhuhr", "0"], ["Asr", "0"], ["Maghrib", "+3"], ["Isha", "0"]].map(([p, v], i, a) => (
          <div key={p} style={{ display: "flex", alignItems: "center", gap: 10, padding: "9px 16px", borderBottom: i === a.length - 1 ? "none" : "1px solid var(--line)" }}>
            <span className="t-title-sm" style={{ flex: 1, fontSize: 14.5 }}>{p}</span>
            <span className="t-caption c-3 t-num">{v === "0" ? "calculated" : v + " min"}</span>
            <Stepper val={v}></Stepper>
          </div>
        ))}
      </div>
    </div>
    <HomeBar style={{ marginTop: "auto" }}></HomeBar>
  </Phone>
);

/* ============ CALENDAR ============ */
const CalScreen = ({ dark, popover }) => {
  const days = Array.from({ length: 30 }, (_, i) => i + 1);
  const special = { 5: "Jumu'ah", 26: "today", 27: "Hajj begins", 28: "Arafah", 29: "Eid al-Adha" };
  return (
    <Phone dark={dark} time="10:15">
      <MiscHead title="Calendar" trail={<QIcon name="chevD" size={18} color="var(--ink-2)"></QIcon>}></MiscHead>
      <div style={{ flex: 1, padding: "12px 22px 0", minHeight: 0, position: "relative" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
          <span className="t-title">June 2026</span>
          <span className="t-caption c-2">· Dhul-Ḥijjah 1447 · <span className="t-bn">জ্যৈষ্ঠ–আষাঢ় ১৪৩৩</span></span>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(7, 1fr)", gap: 4, marginTop: 12 }}>
          {["S", "M", "T", "W", "T", "F", "S"].map((d, i) => (
            <span key={i} className="t-caption c-3" style={{ textAlign: "center", fontSize: 10.5, fontWeight: 700, color: i === 5 ? "var(--primary)" : undefined }}>{d}</span>
          ))}
          <span></span>
          {days.map((d) => {
            const hijri = d + 14 > 29 ? d - 15 : d + 14;
            const isToday = d === 12, isEid = d === 27, isSpec = d === 25 || d === 26;
            return (
              <div key={d} style={{ minHeight: 52, borderRadius: 11, padding: "5px 2px 3px", textAlign: "center", position: "relative",
                background: isToday ? "var(--primary)" : isEid ? "var(--accent-soft)" : "var(--surface)",
                border: "1px solid " + (isToday ? "var(--primary)" : isEid ? "transparent" : "var(--line)"),
                color: isToday ? "var(--on-primary)" : isEid ? "var(--on-accent-soft)" : "var(--ink)" }}>
                <div className="t-num" style={{ fontSize: 13.5, fontWeight: 700 }}>{d}</div>
                <div className="t-num" style={{ fontSize: 8.5, opacity: 0.65 }}>{hijri}</div>
                <div className="t-bn t-num" style={{ fontSize: 8, opacity: 0.5 }}>{bnD(d > 16 ? d - 16 : d + 15)}</div>
                {(isEid || isSpec) && <span style={{ position: "absolute", top: 4, insetInlineEnd: 4, width: 5, height: 5, borderRadius: 99, background: isEid ? "var(--accent-strong)" : "var(--primary)" }}></span>}
              </div>
            );
          })}
        </div>
        <div style={{ display: "flex", gap: 14, marginTop: 12, flexWrap: "wrap" }} className="t-caption c-2">
          <span style={{ display: "inline-flex", alignItems: "center", gap: 5 }}><span style={{ width: 7, height: 7, borderRadius: 99, background: "var(--primary)" }}></span>Islamic date</span>
          <span style={{ display: "inline-flex", alignItems: "center", gap: 5 }}><span style={{ width: 7, height: 7, borderRadius: 99, background: "var(--accent-strong)" }}></span>Eid & major days</span>
        </div>
        <div style={{ marginTop: 12, padding: "12px 16px", borderRadius: "var(--r-md)", background: "var(--surface)", border: "1px solid var(--line)" }}>
          {[["25 Jun", "Hajj begins · 8 Dhul-Ḥijjah"], ["26 Jun", "Day of Arafah — fasting encouraged"], ["27 Jun", "Eid al-Adha ✦"]].map(([d, t]) => (
            <div key={d} style={{ display: "flex", gap: 10, padding: "5px 0" }} className="t-caption">
              <span className="t-num" style={{ color: "var(--primary)", fontWeight: 700, width: 48 }}>{d}</span><span className="c-2">{t}</span>
            </div>
          ))}
        </div>
        {popover && (
          <div style={{ position: "absolute", left: 30, right: 30, top: 190, borderRadius: "var(--r-lg)", background: "var(--surface)", boxShadow: "var(--e-2)", border: "1px solid var(--line)", padding: 18, zIndex: 2 }}>
            <div className="t-title-sm">Friday 12 June 2026</div>
            <div className="t-caption c-2" style={{ marginTop: 3 }}>26 Dhul-Ḥijjah 1447 · <span className="t-bn">২৯ জ্যৈষ্ঠ ১৪৩৩</span></div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6, marginTop: 12 }}>
              {[["Fajr", "3:43"], ["Dhuhr", "12:00"], ["Asr", "4:38"], ["Maghrib", "6:49"], ["Isha", "8:15"], ["Sunrise", "5:10"]].map(([p, t]) => (
                <div key={p} style={{ textAlign: "center", padding: "7px 2px", borderRadius: 9, background: "var(--surface-2)" }}>
                  <div className="t-caption c-3" style={{ fontSize: 9.5 }}>{p}</div>
                  <div className="t-label t-num" style={{ fontSize: 12.5 }}>{t}</div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
      <BottomNav active={4}></BottomNav>
    </Phone>
  );
};

const SecMisc = () => (
  <React.Fragment>
    <DCSection id="ramadan" title="10 · Ramadan" subtitle="Section appears in “More” year-round; during Ramadan it takes a promoted slot on Home and the tab row — never deleting another tab">
      <DCArtboard id="r-home" label="Ramadan home · Light" width={390} height={844}><RamadanHome></RamadanHome></DCArtboard>
      <DCArtboard id="r-home-d" label="Ramadan home · Dark (sahri hour)" width={390} height={844}><RamadanHome dark></RamadanHome></DCArtboard>
      <DCArtboard id="r-zakat" label="Zakat calculator · input" width={390} height={844}><ZakatCalc></ZakatCalc></DCArtboard>
      <DCArtboard id="r-zakat2" label="Zakat · result breakdown" width={390} height={844}><ZakatCalc result></ZakatCalc></DCArtboard>
      <DCArtboard id="r-zakat-d" label="Zakat result — Dark" width={390} height={844}><ZakatCalc result dark></ZakatCalc></DCArtboard>
    </DCSection>
    <DCSection id="mosque" title="11 · My Mosque — jamaat configuration" subtitle="Per-prayer fixed-or-offset · Maghrib defaults to offset +5 · multiple profiles · optional seasonal switching">
      <DCArtboard id="mq-1" label="Mosque config · Light" width={390} height={844}><MyMosque></MyMosque></DCArtboard>
      <DCArtboard id="mq-2" label="Mosque config · Dark" width={390} height={844}><MyMosque dark></MyMosque></DCArtboard>
      <DCArtboard id="mq-3" label="Seasonal profile · advanced" width={390} height={844}><MyMosque seasonal></MyMosque></DCArtboard>
    </DCSection>
    <DCSection id="settings" title="12 · Settings" subtitle="Grouped & scannable — calculation, notifications, appearance, privacy">
      <DCArtboard id="s-main" label="Settings · Light" width={390} height={844}><SettingsScreen></SettingsScreen></DCArtboard>
      <DCArtboard id="s-main-d" label="Settings · Dark" width={390} height={844}><SettingsScreen dark></SettingsScreen></DCArtboard>
      <DCArtboard id="s-notif" label="Notification matrix · per-prayer" width={390} height={844}><NotifMatrix></NotifMatrix></DCArtboard>
      <DCArtboard id="s-adjust" label="Per-prayer minute adjustment" width={390} height={844}><MinuteAdjust dark></MinuteAdjust></DCArtboard>
    </DCSection>
    <DCSection id="calendar" title="13 · Calendar" subtitle="Gregorian + Hijri + Bengali in every cell · legend · tap a day for all three dates + prayer times">
      <DCArtboard id="cal-1" label="Month view · Light" width={390} height={844}><CalScreen></CalScreen></DCArtboard>
      <DCArtboard id="cal-2" label="Month view · Dark" width={390} height={844}><CalScreen dark></CalScreen></DCArtboard>
      <DCArtboard id="cal-3" label="Date detail popover" width={390} height={844}><CalScreen popover></CalScreen></DCArtboard>
    </DCSection>
  </React.Fragment>
);

window.SecMisc = SecMisc;
