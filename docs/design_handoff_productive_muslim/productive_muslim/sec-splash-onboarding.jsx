// productive_muslim/sec-splash-onboarding.jsx
/* global React, DCArtboard, DCSection, Phone, HomeBar, QalbMark, MotifBg, QIcon, Btn, Chip, Field, Radio, Banner, ListRow, SpecNote */

/* ---------- splash ---------- */
const SplashScreen = ({ dark }) => (
  <Phone dark={dark} bare>
    <MotifBg opacity={dark ? 0.05 : 0.045} cell={130} style={{ color: "var(--primary)" }}></MotifBg>
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 0, position: "relative" }}>
      <QalbMark size={128} color="var(--primary)" accent="var(--accent)" sw={2.2}></QalbMark>
      <div className="t-display" style={{ marginTop: 26, letterSpacing: "-.5px" }}>Productive Muslim</div>
      <div className="t-body c-2" style={{ marginTop: 6 }}>a companion for the heart’s daily deen</div>
    </div>
    <div className="t-caption c-3" style={{ textAlign: "center", paddingBottom: 26 }}>works fully offline · v1.0</div>
    <HomeBar></HomeBar>
  </Phone>
);

/* ---------- onboarding scaffold ---------- */
const ObFrame = ({ dark, step, total = 7, title, sub, children, cta = "Continue", ctaKind = "primary", skip, secondary, onPad = true }) => (
  <Phone dark={dark}>
    <div style={{ display: "flex", alignItems: "center", padding: "8px 22px 0", minHeight: 40 }}>
      <div style={{ display: "flex", gap: 5 }}>
        {Array.from({ length: total }).map((_, i) => (
          <span key={i} style={{ width: i === step ? 22 : 7, height: 7, borderRadius: 4,
            background: i <= step ? "var(--primary)" : "var(--surface-2)", border: i <= step ? "none" : "1px solid var(--line)" }}></span>
        ))}
      </div>
      <span style={{ flex: 1 }}></span>
      {skip && <span className="t-label" style={{ color: "var(--ink-3)" }}>Skip</span>}
    </div>
    <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: onPad ? "18px 22px 0" : 0, minHeight: 0 }}>
      {title && <div className="t-headline" style={{ marginBottom: 8 }}>{title}</div>}
      {sub && <div className="t-body c-2" style={{ marginBottom: 20 }}>{sub}</div>}
      {children}
    </div>
    <div style={{ padding: "14px 22px 6px", flexShrink: 0 }}>
      {secondary && <div style={{ marginBottom: 10 }}>{secondary}</div>}
      <Btn kind={ctaKind} full>{cta}</Btn>
    </div>
    <HomeBar></HomeBar>
  </Phone>
);

/* 1 · welcome */
const ObWelcome = ({ dark }) => (
  <Phone dark={dark}>
    <MotifBg opacity={0.04} cell={130} style={{ color: "var(--primary)" }}></MotifBg>
    <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", padding: "0 30px", position: "relative" }}>
      <QalbMark size={84} color="var(--primary)" accent="var(--accent)" sw={2.4}></QalbMark>
      <div className="t-display" style={{ marginTop: 26 }}>Assalamu alaikum.</div>
      <div className="t-body c-2" style={{ marginTop: 12, fontSize: 16.5, lineHeight: 1.55 }}>
        Productive Muslim keeps your prayers, Quran, and daily self-accounting in one quiet place — accurate anywhere on earth, no internet needed.
      </div>
    </div>
    <div style={{ padding: "14px 22px 6px" }}><Btn kind="primary" full>Begin</Btn></div>
    <HomeBar></HomeBar>
  </Phone>
);

/* 2 · language */
const LANGS = [
  ["English", "English", true, false], ["বাংলা", "Bangla", false, true],
  ["العربية", "Arabic · coming soon", false, false, true], ["اردو", "Urdu · coming soon", false, false, true],
  ["Bahasa Indonesia", "Coming soon", false, false, true], ["Türkçe", "Coming soon", false, false, true],
];
const ObLanguage = ({ dark }) => (
  <ObFrame dark={dark} step={0} title="Choose your language" sub="You can change this anytime in Settings.">
    {LANGS.map(([native, name, on, bn, soon]) => (
      <div key={native} style={{ display: "flex", alignItems: "center", gap: 12, minHeight: 56, padding: "0 16px", marginBottom: 9,
        borderRadius: "var(--r-md)", background: "var(--surface)", opacity: soon ? 0.45 : 1,
        border: on ? "2px solid var(--primary)" : "1.5px solid var(--line)" }}>
        <span className={"t-title-sm" + (bn ? " t-bn" : "")} style={{ flex: 1, fontFamily: /[\u0600-\u06FF]/.test(native) ? "var(--font-ar-ui)" : undefined }}>{native}</span>
        <span className="t-caption c-3">{name}</span>
        <Radio on={on}></Radio>
      </div>
    ))}
  </ObFrame>
);

/* 3 · location setup — two paths */
const ObLocation = ({ dark }) => (
  <ObFrame dark={dark} step={1} title="Where are you?" sub="Prayer times are calculated on your device for your exact location. Your location never leaves your phone." cta="Use my location" secondary={<Btn kind="tonal" full icon="search">Choose city manually</Btn>}>
    <div style={{ display: "flex", gap: 12 }}>
      {[["gps", "Use GPS", "One tap, auto-updates when you travel", true], ["search", "Pick a city", "Search any city worldwide", false]].map(([ic, t, s, on]) => (
        <div key={t} style={{ flex: 1, padding: 18, borderRadius: "var(--r-lg)", background: "var(--surface)",
          border: on ? "2px solid var(--primary)" : "1.5px solid var(--line)", boxShadow: on ? "var(--e-1)" : "none" }}>
          <span style={{ width: 44, height: 44, borderRadius: 14, display: "grid", placeItems: "center", background: "var(--primary-soft)", color: "var(--on-primary-soft)" }}>
            <QIcon name={ic} size={22}></QIcon>
          </span>
          <div className="t-title-sm" style={{ marginTop: 12 }}>{t}</div>
          <div className="t-caption c-2" style={{ marginTop: 3 }}>{s}</div>
        </div>
      ))}
    </div>
    <Banner icon="info" style={{ marginTop: 16 }}>
      Next, your phone will ask for location permission — Productive Muslim uses it only to calculate prayer times and qibla, only while open.
    </Banner>
  </ObFrame>
);

/* 3b · manual city picker (also the permission-denied fallback) */
const ObCityPicker = ({ dark, denied }) => (
  <ObFrame dark={dark} step={1} title={denied ? "No problem at all" : "Choose your city"}
    sub={denied ? "GPS is off — everything still works. Pick your city and Productive Muslim calculates locally, fully offline." : "Search any city in the world."} cta="Confirm city">
    {denied && (
      <Banner icon="info" tone="var(--accent-soft)" color="var(--on-accent-soft)" style={{ marginBottom: 14 }}>
        Changed your mind? Enable location anytime in Settings → Location.
      </Banner>
    )}
    <Field icon="search" value="Dha" focus></Field>
    <div style={{ marginTop: 14, background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1.5px solid var(--line)", overflow: "hidden" }}>
      {[["🇧🇩", "Dhaka", "Bangladesh", true], ["🇧🇩", "Dhamrai", "Bangladesh"], ["🇮🇳", "Dhanbad", "India"], ["🇸🇦", "Dhahran", "Saudi Arabia"]].map(([flag, city, country, on], i) => (
        <div key={city} style={{ display: "flex", alignItems: "center", gap: 12, minHeight: 54, padding: "0 16px",
          borderTop: i ? "1px solid var(--line)" : "none", background: on ? "var(--primary-soft)" : "transparent" }}>
          <span style={{ fontSize: 19 }}>{flag}</span>
          <span style={{ flex: 1 }}>
            <span className="t-title-sm" style={{ display: "block", color: on ? "var(--on-primary-soft)" : undefined }}>{city}</span>
            <span className="t-caption c-2">{country}</span>
          </span>
          {on && <QIcon name="check" size={18} color="var(--on-primary-soft)" sw={2.4}></QIcon>}
        </div>
      ))}
    </div>
  </ObFrame>
);

/* 4 · madhab */
const ObMadhab = ({ dark }) => (
  <ObFrame dark={dark} step={2} title="Asr juristic method" sub="This only affects when Asr begins — everything else is identical.">
    {[["Hanafi", "Asr starts later (shadow = 2× object)", "4:38 PM today", true], ["Shafiʿi · Maliki · Hanbali", "Asr starts earlier (shadow = 1× object)", "3:52 PM today", false]].map(([t, s, eg, on]) => (
      <div key={t} style={{ padding: "16px 18px", borderRadius: "var(--r-lg)", marginBottom: 12, background: "var(--surface)",
        border: on ? "2px solid var(--primary)" : "1.5px solid var(--line)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <span className="t-title-sm" style={{ flex: 1 }}>{t}</span><Radio on={on}></Radio>
        </div>
        <div className="t-caption c-2" style={{ marginTop: 4 }}>{s}</div>
        <div className="t-caption" style={{ marginTop: 6, color: "var(--primary)", fontWeight: 700 }}>{eg}</div>
      </div>
    ))}
    <Banner icon="check">Pre-selected for Bangladesh — most of South Asia follows Hanafi.</Banner>
  </ObFrame>
);

/* 5 · calculation method */
const ObMethod = ({ dark }) => (
  <ObFrame dark={dark} step={3} title="Calculation method" sub="Auto-suggested from your country. Scholars differ slightly on twilight angles — pick what your local mosques follow.">
    {[["University of Islamic Sciences, Karachi", "18° / 18° · used across South Asia", true], ["Muslim World League", "18° / 17°", false], ["Egyptian General Authority", "19.5° / 17.5°", false], ["Umm al-Qura, Makkah", "18.5° / 90 min", false]].map(([t, s, on], i) => (
      <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "13px 16px", borderRadius: "var(--r-md)", marginBottom: 9,
        background: "var(--surface)", border: on ? "2px solid var(--primary)" : "1.5px solid var(--line)" }}>
        <span style={{ flex: 1 }}>
          <span className="t-title-sm" style={{ display: "block", fontSize: 14.5 }}>{t}</span>
          <span className="t-caption c-2">{s}</span>
        </span>
        <Radio on={on}></Radio>
      </div>
    ))}
    <div className="t-caption c-3" style={{ textAlign: "center", marginTop: 8 }}>You can change this later in Settings.</div>
  </ObFrame>
);

/* 6 · notification priming + denied */
const ObNotif = ({ dark, denied }) => (
  <ObFrame dark={dark} step={4} title={denied ? "Notifications are off" : "Gentle reminders"}
    sub={denied ? "Productive Muslim stays useful without them — open the app anytime for live countdowns. Re-enable whenever you like." : "Choose what Productive Muslim may remind you about. Your phone will ask once."}
    cta={denied ? "Continue without reminders" : "Allow notifications"} ctaKind={denied ? "tonal" : "primary"}
    secondary={denied ? <Btn kind="ghost" full>Open system settings</Btn> : <Btn kind="ghost" full>Maybe later</Btn>}>
    {[["bell", "Azan at each waqt", "Sound, beep, or silent — per prayer", !denied], ["mosque", "Jamaat reminder", "A nudge before congregation at your mosque", !denied], ["moon", "Sahri & iftar alerts", "During Ramadan", !denied], ["heart", "Evening muhasaba", "One quiet check-in, never more", !denied]].map(([ic, t, s, on]) => (
      <ListRow key={t} icon={ic} title={t} sub={s} trail={<window.Toggle on={on} disabled={denied}></window.Toggle>}
        style={{ background: "var(--surface)", borderRadius: "var(--r-md)", border: "1.5px solid var(--line)", padding: "8px 14px", marginBottom: 9, opacity: denied ? 0.6 : 1 }}></ListRow>
    ))}
  </ObFrame>
);

/* 7 · bismillah */
const ObFinish = ({ dark }) => (
  <Phone dark={dark}>
    <MotifBg opacity={0.05} cell={110} style={{ color: "var(--accent)" }}></MotifBg>
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 36px", textAlign: "center", position: "relative" }}>
      <div className="t-quran" style={{ fontSize: 38, color: "var(--primary)", lineHeight: 1.9 }}>بِسْمِ ٱللَّهِ</div>
      <div className="t-headline" style={{ marginTop: 14 }}>You’re all set, alhamdulillah.</div>
      <div className="t-body c-2" style={{ marginTop: 10 }}>Dhaka · Hanafi · Karachi method.<br></br>Everything can be changed in Settings.</div>
    </div>
    <div style={{ padding: "14px 22px 6px" }}><Btn kind="primary" full icon="heart">Open Productive Muslim</Btn></div>
    <HomeBar></HomeBar>
  </Phone>
);

const PH = 844;
const SecSplashOnboarding = () => (
  <React.Fragment>
    <DCSection id="splash" title="03 · Splash" subtitle="Mark draws itself in ≤2s (squares trace → heart fades in), never blocks — there is no network dependency. Reduced-motion: static mark.">
      <DCArtboard id="sp-l" label="Splash · Light" width={390} height={PH}><SplashScreen></SplashScreen></DCArtboard>
      <DCArtboard id="sp-d" label="Splash · Dark" width={390} height={PH}><SplashScreen dark></SplashScreen></DCArtboard>
    </DCSection>
    <DCSection id="onboarding" title="04 · Onboarding — first launch" subtitle="7 steps · permission priming always precedes the OS dialog · every denial has a graceful path · re-enterable via Settings → “Run setup again”">
      <DCArtboard id="ob-1" label="1 · Welcome" width={390} height={PH}><ObWelcome></ObWelcome></DCArtboard>
      <DCArtboard id="ob-2" label="2 · Language" width={390} height={PH}><ObLanguage></ObLanguage></DCArtboard>
      <DCArtboard id="ob-3" label="3 · Location — two paths + priming" width={390} height={PH}><ObLocation></ObLocation></DCArtboard>
      <DCArtboard id="ob-3b" label="3b · Manual city picker" width={390} height={PH}><ObCityPicker></ObCityPicker></DCArtboard>
      <DCArtboard id="ob-3c" label="3c · Permission DENIED fallback" width={390} height={PH}><ObCityPicker denied></ObCityPicker></DCArtboard>
      <DCArtboard id="ob-4" label="4 · Madhab (pre-selected by region)" width={390} height={PH}><ObMadhab></ObMadhab></DCArtboard>
      <DCArtboard id="ob-5" label="5 · Calculation method" width={390} height={PH}><ObMethod></ObMethod></DCArtboard>
      <DCArtboard id="ob-6" label="6 · Notification priming" width={390} height={PH}><ObNotif></ObNotif></DCArtboard>
      <DCArtboard id="ob-6b" label="6b · Notifications DENIED" width={390} height={PH}><ObNotif denied></ObNotif></DCArtboard>
      <DCArtboard id="ob-7" label="7 · Bismillah → Home" width={390} height={PH}><ObFinish></ObFinish></DCArtboard>
    </DCSection>
    <DCSection id="onboarding-dark" title="04b · Onboarding — dark theme" subtitle="Same flow, deliberately designed dark surfaces">
      <DCArtboard id="obd-1" label="1 · Welcome" width={390} height={PH}><ObWelcome dark></ObWelcome></DCArtboard>
      <DCArtboard id="obd-2" label="2 · Language" width={390} height={PH}><ObLanguage dark></ObLanguage></DCArtboard>
      <DCArtboard id="obd-3" label="3 · Location" width={390} height={PH}><ObLocation dark></ObLocation></DCArtboard>
      <DCArtboard id="obd-3c" label="3c · Denied fallback" width={390} height={PH}><ObCityPicker dark denied></ObCityPicker></DCArtboard>
      <DCArtboard id="obd-4" label="4 · Madhab" width={390} height={PH}><ObMadhab dark></ObMadhab></DCArtboard>
      <DCArtboard id="obd-5" label="5 · Method" width={390} height={PH}><ObMethod dark></ObMethod></DCArtboard>
      <DCArtboard id="obd-6" label="6 · Notifications" width={390} height={PH}><ObNotif dark></ObNotif></DCArtboard>
      <DCArtboard id="obd-7" label="7 · Bismillah" width={390} height={PH}><ObFinish dark></ObFinish></DCArtboard>
    </DCSection>
  </React.Fragment>
);

window.SecSplashOnboarding = SecSplashOnboarding;
