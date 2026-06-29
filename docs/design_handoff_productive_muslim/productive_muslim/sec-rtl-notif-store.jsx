// productive_muslim/sec-rtl-notif-store.jsx — RTL set · notifications · icon & store
/* global React, DCArtboard, DCSection, Phone, HomeBar, AppHeader, CountdownCard, PrayerTable, BottomNav, NotifCard,
   ProgressRing, Heatmap, CompassDial, QIcon, QalbMark, Star8, MotifBg, Btn, Toggle, Banner, SegControl, SpecNote, arD, HEART_PATH */

/* ============ RTL — Arabic locale ============ */
const AR_ROWS = [
  { name: "الفجر", time: "٣:٤٣ – ٥:١٠ ص", jamaat: "٤:١٥", done: true },
  { name: "الشروق", time: "٥:١٠ ص", sunrise: true },
  { name: "الظهر", time: "١٢:٠٠ – ٤:٣٨ م", jamaat: "١:٣٠", done: true },
  { name: "العصر", time: "٤:٣٨ – ٦:٤٩ م", jamaat: "٥:١٥" },
  { name: "المغرب", time: "٦:٤٩ – ٨:١٥ م", jamaat: "٦:٥٤" },
  { name: "العشاء", time: "٨:١٥ م – ٣:٤٣ ص" },
];
const HomeRTL = ({ dark }) => (
  <Phone dark={dark} dir="rtl" time="٤:٥٥" style={{ fontFamily: "var(--font-ar-ui)" }}>
    <AppHeader city="القاهرة، مصر" dates={["الجمعة ١٢ يونيو ٢٠٢٦", "٢٦ ذو الحجة ١٤٤٧"]}></AppHeader>
    <div style={{ flex: 1, padding: "14px 22px 0", minHeight: 0 }}>
      <CountdownCard state="calm" eyebrow="العصر · ينتهي بعد" big="٢:٤١:٠٩" sub="التالي: المغرب ٦:٤٩ م · الجماعة ٥:١٥ م" pct={0.35}></CountdownCard>
      <div style={{ display: "flex", gap: 10, marginTop: 12 }}>
        {[["moon", "نهاية السحور", "٣:٤٣ ص"], ["sun", "الإفطار", "٦:٤٩ م"]].map(([ic, t, v]) => (
          <div key={t} style={{ flex: 1, display: "flex", alignItems: "center", gap: 10, padding: "12px 14px", borderRadius: "var(--r-md)", background: "var(--surface)", border: "1px solid var(--line)" }}>
            <QIcon name={ic} size={17} color="var(--accent-strong)"></QIcon>
            <span style={{ flex: 1 }}>
              <span className="t-caption" style={{ display: "block", opacity: 0.75, fontSize: 10.5 }}>{t}</span>
              <span className="t-label t-num" style={{ fontSize: 14.5 }}>{v}</span>
            </span>
          </div>
        ))}
      </div>
      <div style={{ display: "flex", alignItems: "baseline", padding: "14px 4px 7px" }}>
        <span className="t-label c-2">صلوات اليوم</span><span style={{ flex: 1 }}></span>
        <span className="t-caption c-3">الجماعة · صُلّيت</span>
      </div>
      <PrayerTable rows={AR_ROWS} activeIdx={3} labels={{ set: "حدد الجماعة" }}></PrayerTable>
    </div>
    <BottomNav active={0} lang="ar"></BottomNav>
  </Phone>
);

const AR_AYAHS = [
  ["بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ", 1], ["ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ", 2],
  ["ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ", 3], ["مَـٰلِكِ يَوْمِ ٱلدِّينِ", 4], ["إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", 5],
];
const QuranRTL = ({ dark }) => (
  <Phone dark={dark} dir="rtl" time="١١:٣٨" style={{ fontFamily: "var(--font-ar-ui)" }}>
    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "6px 20px 10px", borderBottom: "1px solid var(--line)", background: "var(--surface)" }}>
      <QIcon name="back" size={22} style={{ transform: "scaleX(-1)" }}></QIcon>
      <span style={{ flex: 1, textAlign: "center" }}>
        <span className="t-title-sm t-quran" style={{ display: "block", fontSize: 19 }}>سُورَةُ ٱلْفَاتِحَة</span>
        <span className="t-caption c-3">مكية · ٧ آيات</span>
      </span>
      <QIcon name="gear" size={20} color="var(--ink-2)"></QIcon>
    </div>
    <div style={{ height: 3, background: "var(--surface-2)" }}><div style={{ width: "57%", height: "100%", background: "var(--primary)", marginInlineStart: 0 }}></div></div>
    <div style={{ flex: 1, padding: "16px 20px 0", minHeight: 0 }}>
      <div style={{ padding: "20px 18px", borderRadius: "var(--r-lg)", background: "var(--surface)", border: "1px solid var(--line)" }}>
        <div className="t-quran" style={{ fontSize: 28, lineHeight: 2.2, textAlign: "justify" }}>
          {AR_AYAHS.map(([a, n]) => (
            <React.Fragment key={n}>{a} <span style={{ fontSize: 20, color: "var(--accent-strong)" }}>﴿{arD(String(n))}﴾</span> </React.Fragment>
          ))}
        </div>
      </div>
      <div style={{ display: "flex", gap: 20, justifyContent: "center", marginTop: 16, color: "var(--ink-3)" }}>
        <QIcon name="bookmark" size={18}></QIcon><QIcon name="copy" size={18}></QIcon><QIcon name="share" size={18}></QIcon><QIcon name="play" size={18}></QIcon>
      </div>
    </div>
    <BottomNav active={1} lang="ar"></BottomNav>
  </Phone>
);

const ArRow = ({ icon, t, v, toggle, on, last }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 12, minHeight: 52, padding: "0 16px", borderBottom: last ? "none" : "1px solid var(--line)" }}>
    <QIcon name={icon} size={18} color="var(--ink-2)"></QIcon>
    <span style={{ flex: 1, fontSize: 14.5, fontWeight: 500 }}>{t}</span>
    {toggle ? <Toggle on={on}></Toggle> : (
      <React.Fragment>
        {v && <span className="t-caption c-2">{v}</span>}
        <QIcon name="chevR" size={15} color="var(--ink-3)" style={{ transform: "scaleX(-1)" }}></QIcon>
      </React.Fragment>
    )}
  </div>
);
const SettingsRTL = ({ dark }) => (
  <Phone dark={dark} dir="rtl" time="٨:٤٤" style={{ fontFamily: "var(--font-ar-ui)" }}>
    <div style={{ textAlign: "center", padding: "6px 22px 0" }} className="t-title">الإعدادات</div>
    <div style={{ flex: 1, padding: "0 22px", minHeight: 0 }}>
      {[["حساب الصلاة", [["pin", "الموقع", "القاهرة · GPS"], ["book", "مذهب العصر", "شافعي"], ["globe", "طريقة الحساب", "الهيئة المصرية"], ["gear", "تعديل الدقائق", "الفجر +٢"]]],
        ["الإشعارات", [["bell", "الأذان والتنبيهات", "مخصص"], ["mosque", "تذكير الجماعة", null, true, true], ["heart", "محاسبة المساء", null, true, true]]],
        ["المظهر واللغة", [["sun", "السمة", "النظام"], ["globe", "اللغة", "العربية"], ["book", "حجم خط القرآن", "٢٧"]]]].map(([g, rows]) => (
        <React.Fragment key={g}>
          <div className="t-overline c-3" style={{ fontSize: 10, margin: "16px 2px 7px" }}>{g}</div>
          <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)", overflow: "hidden" }}>
            {rows.map(([ic, t, v, tg, on], i) => <ArRow key={t} icon={ic} t={t} v={v} toggle={tg} on={on} last={i === rows.length - 1}></ArRow>)}
          </div>
        </React.Fragment>
      ))}
    </div>
    <BottomNav active={4} lang="ar"></BottomNav>
  </Phone>
);

/* ============ NOTIFICATIONS ============ */
const NotifStack = ({ dark, os }) => (
  <div className={dark ? "q-dark" : "q-light"} style={{ width: "100%", height: "100%", background: dark ? "linear-gradient(180deg,#101b18,#0a100e)" : "linear-gradient(180deg,#DCE5DF,#C9D6CF)", borderRadius: 24, padding: "26px 16px", fontFamily: "var(--font-ui)", position: "relative", overflow: "hidden" }}>
    <div style={{ textAlign: "center", color: dark ? "#E4E9E4" : "#1F2A26", marginBottom: 18 }}>
      <div className="t-num" style={{ fontSize: 54, fontWeight: 300, letterSpacing: "-1px" }}>4:38</div>
      <div className="t-caption" style={{ opacity: 0.7 }}>Friday, June 12 · {os === "ios" ? "iOS" : "Android"}</div>
    </div>
    <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
      <NotifCard os={os} dark={dark} time="now" title="Time for Asr · 4:38 PM" body="Dhaka · waqt until 6:49 PM. The azan is playing on your chosen sound." actions={["Mark as prayed", "Silence today"]}></NotifCard>
      <NotifCard os={os} dark={dark} time="10 min" title="Jamaat in 10 minutes" body="Asr at Masjid An-Noor · 5:15 PM — time for wudu." actions={["On my way"]}></NotifCard>
      <NotifCard os={os} dark={dark} time="3:13 AM" title="Sahri ends in 30 minutes" body="Eat and drink until 3:43 AM. Fajr jamaat at 4:15 AM."></NotifCard>
      <NotifCard os={os} dark={dark} time="6:49 PM" tone="var(--accent)" title="It’s iftar time — alhamdulillah 🌙" body="May Allah accept your fast. Maghrib jamaat in 5 minutes." actions={["Mark roza complete"]}></NotifCard>
      <NotifCard os={os} dark={dark} time="9:30 PM" title="A quiet minute before sleep?" body="Today’s muhasaba is at 70% — Isha and Quran are still open." actions={["Open muhasaba"]}></NotifCard>
      <NotifCard os={os} dark={dark} time="5:11 AM" tone="var(--accent)" title="12 mornings of Fajr, mashallah" body="Your longest streak yet. Gently does it." actions={["See dashboard"]}></NotifCard>
    </div>
  </div>
);

const NotifDeniedEdu = ({ dark }) => (
  <Phone dark={dark} time="8:45">
    <div style={{ display: "flex", alignItems: "center", padding: "6px 22px 0" }}>
      <QIcon name="back" size={22}></QIcon>
      <span className="t-title" style={{ flex: 1, textAlign: "center" }}>Azan & alerts</span>
      <span style={{ width: 22 }}></span>
    </div>
    <div style={{ flex: 1, padding: "18px 22px 0" }}>
      <div style={{ padding: 20, borderRadius: "var(--r-lg)", background: "var(--surface)", border: "1px solid var(--line)", textAlign: "center" }}>
        <span style={{ width: 58, height: 58, borderRadius: 20, display: "inline-grid", placeItems: "center", background: "var(--surface-2)", color: "var(--ink-2)" }}>
          <QIcon name="bellOff" size={26}></QIcon>
        </span>
        <div className="t-title" style={{ marginTop: 14 }}>Notifications are off for Productive Muslim</div>
        <div className="t-body c-2" style={{ marginTop: 8, textAlign: "start" }}>
          That’s okay — nothing breaks. Countdowns, prayer times, and muhasaba all work whenever you open the app.
          If you’d like the azan and gentle reminders back:
        </div>
        <div style={{ textAlign: "start", marginTop: 12 }} className="t-body c-2">
          <div style={{ display: "flex", gap: 10, marginBottom: 8 }}><b style={{ color: "var(--primary)" }}>1</b><span>Open your phone’s <b style={{ color: "var(--ink)" }}>Settings → Apps → Productive Muslim</b></span></div>
          <div style={{ display: "flex", gap: 10, marginBottom: 8 }}><b style={{ color: "var(--primary)" }}>2</b><span>Tap <b style={{ color: "var(--ink)" }}>Notifications</b> and allow</span></div>
          <div style={{ display: "flex", gap: 10 }}><b style={{ color: "var(--primary)" }}>3</b><span>Come back — your per-prayer choices are saved</span></div>
        </div>
        <div style={{ marginTop: 18 }}><Btn kind="primary" full>Open system settings</Btn></div>
      </div>
      <Banner icon="info" style={{ marginTop: 14 }}>Productive Muslim never uses notifications for promotions — only what you chose: azan, jamaat, sahri/iftar, and one evening muhasaba nudge.</Banner>
    </div>
    <HomeBar style={{ marginTop: "auto" }}></HomeBar>
  </Phone>
);

/* ============ ICON & STORE ============ */
const AppIcon = ({ size = 96, shape = "squircle", dark }) => (
  <div style={{ width: size, height: size, borderRadius: shape === "circle" ? "50%" : size * 0.24, position: "relative", overflow: "hidden",
    background: dark ? "#10201C" : "#15564D", display: "grid", placeItems: "center", boxShadow: "0 2px 8px rgba(20,40,35,.25)" }}>
    <svg width={size * 0.66} height={size * 0.66} viewBox="0 0 96 96" fill="none">
      <g stroke={dark ? "#79C7B6" : "#EAF3EF"} strokeWidth="4">
        <rect x="21" y="21" width="54" height="54" rx="7"></rect>
        <rect x="21" y="21" width="54" height="54" rx="7" transform="rotate(45 48 48)"></rect>
      </g>
      <path d={HEART_PATH} fill="#E2B264"></path>
    </svg>
  </div>
);

const IconBoard = () => (
  <div className="q-light" style={{ height: "100%", padding: 26, background: "var(--bg)", fontFamily: "var(--font-ui)", color: "var(--ink)" }}>
    <div style={{ display: "flex", gap: 22, alignItems: "flex-end" }}>
      <div style={{ textAlign: "center" }}><AppIcon size={110}></AppIcon><div className="t-caption c-2" style={{ marginTop: 8 }}>iOS · 1024</div></div>
      <div style={{ textAlign: "center" }}><AppIcon size={110} shape="circle"></AppIcon><div className="t-caption c-2" style={{ marginTop: 8 }}>Android adaptive</div></div>
      <div style={{ textAlign: "center" }}><AppIcon size={110} dark></AppIcon><div className="t-caption c-2" style={{ marginTop: 8 }}>Themed / dark</div></div>
    </div>
    <window.SpecLabel>Legibility floor — carries the qalb at 48px</window.SpecLabel>
    <div style={{ display: "flex", gap: 16, alignItems: "flex-end" }}>
      {[72, 48, 32].map((s) => <div key={s} style={{ textAlign: "center" }}><AppIcon size={s}></AppIcon><div className="t-caption c-3" style={{ marginTop: 6, fontSize: 10 }}>{s}px</div></div>)}
    </div>
    <window.SpecLabel>Adaptive safe zone</window.SpecLabel>
    <div className="t-caption c-2" style={{ lineHeight: 1.6 }}>Mark occupies 66% of canvas — survives circle, squircle, and rounded-square masks. Foreground layer: star + heart only; background layer: flat primary. No gradients, no photo.</div>
  </div>
);

const FeatureGraphic = () => (
  <div className="q-light" style={{ width: "100%", height: "100%", background: "var(--primary)", position: "relative", overflow: "hidden", display: "flex", alignItems: "center", padding: "0 44px", gap: 36, fontFamily: "var(--font-ui)", borderRadius: 14 }}>
    <MotifBg opacity={0.07} cell={120} style={{ color: "#fff" }}></MotifBg>
    <div style={{ position: "relative", color: "var(--on-primary)", flex: 1 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <QalbMark size={44} color="var(--on-primary)" accent="var(--accent)" sw={3}></QalbMark>
        <span style={{ fontSize: 30, fontWeight: 700, letterSpacing: "-.5px" }}>Productive Muslim</span>
      </div>
      <div style={{ fontSize: 17, opacity: 0.85, marginTop: 10, maxWidth: 330, lineHeight: 1.45 }}>A companion for the heart’s daily deen — prayer, Quran & muhasaba, fully offline.</div>
    </div>
    <div style={{ position: "relative", width: 168, flexShrink: 0 }}>
      <CountdownCard state="iftar" eyebrow="Iftar in" big="12:33" sub="Maghrib 6:49 PM" pct={0.61} style={{ transform: "rotate(4deg) scale(.92)", transformOrigin: "center" }}></CountdownCard>
    </div>
  </div>
);

const StoreFrame = ({ caption, sub, children, tone = "var(--primary)", fg = "var(--on-primary)" }) => (
  <div className="q-light" style={{ width: "100%", height: "100%", background: tone, borderRadius: 18, position: "relative", overflow: "hidden", display: "flex", flexDirection: "column", fontFamily: "var(--font-ui)" }}>
    <MotifBg opacity={0.06} cell={90} style={{ color: fg }}></MotifBg>
    <div style={{ position: "relative", padding: "24px 22px 6px", color: fg }}>
      <div style={{ fontSize: 21, fontWeight: 700, letterSpacing: "-.3px", lineHeight: 1.2 }}>{caption}</div>
      <div className="t-caption" style={{ opacity: 0.8, marginTop: 5 }}>{sub}</div>
    </div>
    <div style={{ position: "relative", flex: 1, display: "grid", placeItems: "center", padding: "8px 24px 26px" }}>{children}</div>
  </div>
);

const SecRtlNotifStore = () => (
  <React.Fragment>
    <DCSection id="rtl" title="14 · RTL set — Arabic locale" subtitle="Fully mirrored: leading edge flips, chevrons & back arrows flip, numerals localize, tables right-align · IBM Plex Sans Arabic UI">
      <DCArtboard id="rtl-home" label="Home · RTL — Light" width={390} height={844}><HomeRTL></HomeRTL></DCArtboard>
      <DCArtboard id="rtl-home-d" label="Home · RTL — Dark" width={390} height={844}><HomeRTL dark></HomeRTL></DCArtboard>
      <DCArtboard id="rtl-quran" label="Quran reader · RTL (mushaf flow)" width={390} height={844}><QuranRTL dark></QuranRTL></DCArtboard>
      <DCArtboard id="rtl-set" label="Settings · RTL" width={390} height={844}><SettingsRTL></SettingsRTL></DCArtboard>
    </DCSection>
    <DCSection id="notifs" title="15 · Notifications as artifacts" subtitle="Every notification earns its interruption · iftar & streaks borrow the warm accent · muhasaba nudge is one per evening, max">
      <DCArtboard id="n-android" label="Android stack · Light" width={400} height={780}><NotifStack os="android"></NotifStack></DCArtboard>
      <DCArtboard id="n-ios" label="iOS stack · Dark" width={400} height={780}><NotifStack os="ios" dark></NotifStack></DCArtboard>
      <DCArtboard id="n-denied" label="In-app · permission-denied education" width={390} height={844}><NotifDeniedEdu></NotifDeniedEdu></DCArtboard>
    </DCSection>
    <DCSection id="store" title="16 · App icon & store assets" subtitle="Icon carries the qalb mark to 48px · feature graphic · 6 screenshot frames">
      <DCArtboard id="st-icon" label="App icon — adaptive + sizes" width={440} height={560}><IconBoard></IconBoard></DCArtboard>
      <DCArtboard id="st-feature" label="Feature graphic · 1024×500" width={614} height={300}><FeatureGraphic></FeatureGraphic></DCArtboard>
      <DCArtboard id="st-1" label="Frame 1" width={300} height={650}>
        <StoreFrame caption="Prayer times, anywhere on earth" sub="Calculated on your phone — no internet, ever">
          <div style={{ width: 252 }}><CountdownCard state="calm" eyebrow="Asr · ends in" big="2:41" sub="Next: Maghrib 6:49 PM" pct={0.35}></CountdownCard></div>
        </StoreFrame>
      </DCArtboard>
      <DCArtboard id="st-2" label="Frame 2" width={300} height={650}>
        <StoreFrame caption="Always find the qibla" sub="Live compass with a gentle aligned moment" tone="#0E1513" fg="#E4E9E4">
          <div className="q-dark" style={{ display: "grid", placeItems: "center" }}><CompassDial aligned size={230}></CompassDial></div>
        </StoreFrame>
      </DCArtboard>
      <DCArtboard id="st-3" label="Frame 3" width={300} height={650}>
        <StoreFrame caption="Quran, beautifully offline" sub="Certified mushaf type · adjustable, restful reading" tone="#F6F4EE" fg="#1F2A26">
          <div className="q-light" style={{ width: 248, padding: "18px 16px", borderRadius: 16, background: "var(--surface)", border: "1px solid var(--line)", boxShadow: "var(--e-2)" }}>
            <div className="t-quran" style={{ fontSize: 23, lineHeight: 2.1, color: "var(--ink)" }}>ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ <span style={{ color: "var(--accent-strong)", fontSize: 17 }}>﴿٢﴾</span></div>
            <div className="t-caption c-2" style={{ marginTop: 8 }}>All praise is for Allah — Lord of all worlds</div>
          </div>
        </StoreFrame>
      </DCArtboard>
      <DCArtboard id="st-4" label="Frame 4" width={300} height={650}>
        <StoreFrame caption="Count your blessings" sub="A tasbih that feels like beads" tone="#0E1513" fg="#E4E9E4">
          <div className="q-dark"><ProgressRing pct={21 / 33} size={200} sw={12} color="var(--primary)">
            <div className="t-num" style={{ fontSize: 60, fontWeight: 700, color: "var(--ink)" }}>21</div>
            <div className="t-caption" style={{ color: "var(--ink-2)" }}>of 33</div>
          </ProgressRing></div>
        </StoreFrame>
      </DCArtboard>
      <DCArtboard id="st-5" label="Frame 5" width={300} height={650}>
        <StoreFrame caption="Know yourself — Muhasaba" sub="A gentle daily account · never a guilt trip" tone="#F6F4EE" fg="#1F2A26">
          <div className="q-light" style={{ width: 248, padding: 16, borderRadius: 16, background: "var(--surface)", border: "1px solid var(--line)", boxShadow: "var(--e-2)" }}>
            <div className="t-label" style={{ marginBottom: 10 }}>Better than last week</div>
            <Heatmap data={[[1, 2, 3, 2, 4, 3, 4], [3, 4, 2, 1, 0, 2, 3], [4, 4, 3, 2, 3, 4, 4], [2, 3, 4, 4, 3, 2, 1]]} cell={13} gap={3.5}></Heatmap>
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 10, color: "var(--accent-strong)" }}>
              <QIcon name="spark" size={14}></QIcon><span className="t-caption" style={{ fontWeight: 700 }}>12-day Fajr streak</span>
            </div>
          </div>
        </StoreFrame>
      </DCArtboard>
      <DCArtboard id="st-6" label="Frame 6" width={300} height={650}>
        <StoreFrame caption="Your Ramadan companion" sub="Sahri & iftar, roza counter, zakat — all offline">
          <div style={{ width: 252, display: "flex", flexDirection: "column", gap: 10 }}>
            <CountdownCard state="sahri" eyebrow="Sahri ends in" big="42:18" sub="Fajr 3:43 AM" pct={0.7}></CountdownCard>
            <CountdownCard state="iftar" eyebrow="Iftar in" big="1:12" sub="Maghrib 6:49 PM" pct={0.61}></CountdownCard>
          </div>
        </StoreFrame>
      </DCArtboard>
    </DCSection>
  </React.Fragment>
);

window.SecRtlNotifStore = SecRtlNotifStore;
