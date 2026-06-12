// qalbee/sec-quran-dua.jsx
/* global React, DCArtboard, DCSection, Phone, HomeBar, BottomNav, QIcon, QalbMark, Star8, MotifBg, Btn, Chip, Field,
   Card, SegControl, Banner, ProgressRing, Skel, SpecNote, arD */

/* ============ QURAN ============ */
const SURAHS = [
  [1, "ٱلْفَاتِحَة", "Al-Fātiḥah", "The Opening", 7, "M"],
  [2, "ٱلْبَقَرَة", "Al-Baqarah", "The Cow", 286, "D"],
  [3, "آلِ عِمْرَان", "Āli ʿImrān", "Family of Imran", 200, "D"],
  [4, "ٱلنِّسَاء", "An-Nisā", "The Women", 176, "D"],
  [18, "ٱلْكَهْف", "Al-Kahf", "The Cave", 110, "M"],
  [36, "يس", "Yā-Sīn", "Ya Sin", 83, "M"],
  [55, "ٱلرَّحْمَـٰن", "Ar-Raḥmān", "The Merciful", 78, "D"],
  [67, "ٱلْمُلْك", "Al-Mulk", "The Sovereignty", 30, "M"],
];
const SurahRow = ({ s, last }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 13, minHeight: 62, padding: "0 16px", borderBottom: last ? "none" : "1px solid var(--line)" }}>
    <span style={{ width: 36, height: 36, flexShrink: 0, display: "grid", placeItems: "center", position: "relative" }}>
      <Star8 size={36} color="var(--line)" sw={2.2}></Star8>
      <span className="t-caption t-num" style={{ position: "absolute", fontWeight: 700, color: "var(--ink-2)", fontSize: 11 }}>{s[0]}</span>
    </span>
    <span style={{ flex: 1, minWidth: 0 }}>
      <span className="t-title-sm" style={{ display: "block", fontSize: 15 }}>{s[2]}</span>
      <span className="t-caption c-2" style={{ display: "flex", alignItems: "center", gap: 5 }}>
        {s[3]} · {s[4]} ayahs
        <QIcon name={s[5] === "M" ? "kaaba" : "mosque"} size={11} color="var(--ink-3)"></QIcon>
      </span>
    </span>
    <span className="t-quran" style={{ fontSize: 21, color: "var(--primary)" }}>{s[1]}</span>
  </div>
);

const SurahList = ({ dark, firstOpen, searchEmpty }) => (
  <Phone dark={dark} time="9:14">
    <div style={{ padding: "6px 22px 0" }}>
      <div style={{ display: "flex", alignItems: "center" }}>
        <span className="t-headline">Quran</span><span style={{ flex: 1 }}></span>
        <QIcon name="bookmark" size={21} color="var(--ink-2)"></QIcon>
      </div>
      <Field icon="search" value={searchEmpty ? "Al-Khaf" : ""} placeholder="Surah name or number" focus={searchEmpty} style={{ marginTop: 12 }}></Field>
      <SegControl opts={["Surah", "Juz", "Bookmarks"]} active={0} style={{ marginTop: 12 }}></SegControl>
    </div>
    <div style={{ flex: 1, padding: "12px 22px 0", minHeight: 0, overflow: "hidden" }}>
      {searchEmpty ? (
        <div style={{ textAlign: "center", paddingTop: 70 }}>
          <QIcon name="search" size={40} color="var(--ink-3)"></QIcon>
          <div className="t-title-sm" style={{ marginTop: 12 }}>No surah matches “Al-Khaf”</div>
          <div className="t-caption c-2" style={{ marginTop: 4 }}>Did you mean <span style={{ color: "var(--primary)", fontWeight: 700 }}>Al-Kahf (18)</span>?</div>
        </div>
      ) : (
        <React.Fragment>
          {firstOpen ? (
            <div style={{ borderRadius: "var(--r-lg)", padding: 16, background: "var(--primary-soft)", color: "var(--on-primary-soft)", display: "flex", gap: 12, alignItems: "center", marginBottom: 12 }}>
              <QIcon name="book" size={24}></QIcon>
              <span className="t-caption" style={{ fontSize: 12.5, lineHeight: 1.5 }}>Welcome. Start anywhere — Qalbee will remember your place and offer to resume here.</span>
            </div>
          ) : (
            <div style={{ borderRadius: "var(--r-lg)", padding: "14px 16px", background: "var(--primary)", color: "var(--on-primary)", position: "relative", overflow: "hidden", marginBottom: 12 }}>
              <MotifBg opacity={0.08} cell={90}></MotifBg>
              <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 12 }}>
                <span style={{ flex: 1 }}>
                  <span className="t-overline" style={{ opacity: 0.75, fontSize: 10 }}>Continue reading</span>
                  <span className="t-title-sm" style={{ display: "block", marginTop: 3 }}>Al-Kahf · ayah 28</span>
                  <span className="t-caption" style={{ opacity: 0.75 }}>bookmarked yesterday — 25% of surah</span>
                </span>
                <QIcon name="play" size={26}></QIcon>
              </div>
            </div>
          )}
          <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)", overflow: "hidden" }}>
            {SURAHS.slice(0, firstOpen ? 8 : 7).map((s, i, a) => <SurahRow key={s[0]} s={s} last={i === a.length - 1}></SurahRow>)}
          </div>
        </React.Fragment>
      )}
    </div>
    <BottomNav active={1}></BottomNav>
  </Phone>
);

/* ---- reader ---- */
const AYAHS = [
  ["بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ", "In the name of Allah — the Most Compassionate, Most Merciful.", 1],
  ["ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ", "All praise is for Allah — Lord of all worlds,", 2],
  ["ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ", "the Most Compassionate, Most Merciful,", 3],
  ["مَـٰلِكِ يَوْمِ ٱلدِّينِ", "Master of the Day of Judgment.", 4],
];
const AyahBlock = ({ a, t, n, arOnly, active, size = 27 }) => (
  <div style={{ padding: "16px 18px", borderRadius: "var(--r-md)", marginBottom: 10,
    background: active ? "var(--primary-soft)" : "var(--surface)",
    border: "1px solid " + (active ? "transparent" : "var(--line)") }}>
    <div className="t-quran" style={{ fontSize: size, lineHeight: 2.05, color: active ? "var(--on-primary-soft)" : "var(--ink)" }}>
      {a} <span style={{ fontSize: size * 0.72, color: "var(--accent-strong)" }}>﴿{arD(String(n))}﴾</span>
    </div>
    {!arOnly && <div className="t-body c-2" style={{ marginTop: 9, fontSize: 14 }}>{t}</div>}
    <div style={{ display: "flex", gap: 18, marginTop: 11, color: "var(--ink-3)" }}>
      <QIcon name="bookmark" size={16} color={active ? "var(--primary)" : undefined} fill={active ? "var(--primary)" : "none"}></QIcon>
      <QIcon name="copy" size={16}></QIcon>
      <QIcon name="share" size={16}></QIcon>
      <QIcon name="play" size={16}></QIcon>
      <span className="t-caption c-3" style={{ marginInlineStart: "auto", fontSize: 10.5 }}>1:{n}</span>
    </div>
  </div>
);

const QuranReader = ({ dark, arOnly, fontSheet, w = 390, h = 844, cols }) => (
  <Phone dark={dark} w={w} h={h} time="11:38">
    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "6px 20px 10px", borderBottom: "1px solid var(--line)", background: "var(--surface)", flexShrink: 0 }}>
      <QIcon name="back" size={22}></QIcon>
      <span style={{ flex: 1, textAlign: "center" }}>
        <span className="t-title-sm" style={{ display: "block" }}>Al-Fātiḥah <span className="t-quran" style={{ fontSize: 17, color: "var(--primary)" }}>ٱلْفَاتِحَة</span></span>
        <span className="t-caption c-3">Makkah · 7 ayahs · 57% read</span>
      </span>
      <QIcon name="gear" size={20} color="var(--ink-2)"></QIcon>
    </div>
    <div style={{ height: 3, background: "var(--surface-2)", flexShrink: 0 }}>
      <div style={{ width: "57%", height: "100%", background: "var(--primary)" }}></div>
    </div>
    <div style={{ flex: 1, padding: "14px 20px 0", minHeight: 0, overflow: "hidden", columnCount: cols, columnGap: 18 }}>
      <div className="t-quran" style={{ textAlign: "center", fontSize: 20, color: "var(--accent-strong)", marginBottom: 12 }}>۞</div>
      {AYAHS.map(([a, t, n]) => <AyahBlock key={n} a={a} t={t} n={n} arOnly={arOnly} active={n === 2 && !arOnly} size={arOnly ? 31 : 27}></AyahBlock>)}
    </div>
    {fontSheet && (
      <div style={{ position: "absolute", inset: 0, background: "var(--scrim)", display: "flex", flexDirection: "column", justifyContent: "flex-end", borderRadius: 24 }}>
        <div className={dark ? "q-dark" : "q-light"} style={{ background: "var(--surface)", borderRadius: "24px 24px 24px 24px", padding: "10px 22px 26px", boxShadow: "var(--e-2)", color: "var(--ink)" }}>
          <div style={{ width: 40, height: 4.5, borderRadius: 3, background: "var(--line)", margin: "0 auto 16px" }}></div>
          <div className="t-title" style={{ marginBottom: 14 }}>Reading settings</div>
          <div className="t-label c-2" style={{ marginBottom: 8 }}>Arabic size — independent of system scale</div>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <span className="t-quran" style={{ fontSize: 17 }}>ا</span>
            <div style={{ flex: 1, height: 5, borderRadius: 3, background: "var(--surface-2)", position: "relative" }}>
              <div style={{ width: "45%", height: "100%", borderRadius: 3, background: "var(--primary)" }}></div>
              <span style={{ position: "absolute", left: "45%", top: "50%", transform: "translate(-50%,-50%)", width: 24, height: 24, borderRadius: 99, background: "var(--primary)", border: "3px solid var(--surface)", boxShadow: "var(--e-1)" }}></span>
            </div>
            <span className="t-quran" style={{ fontSize: 30 }}>ا</span>
          </div>
          <div className="t-label c-2" style={{ margin: "18px 0 8px" }}>Translation</div>
          <SegControl opts={["Shown", "Arabic only"]} active={0}></SegControl>
          <div className="t-caption c-3" style={{ marginTop: 14 }}>Font: KFGQPC Uthmanic Script HAFS — certified mushaf rendering with full harakat.</div>
        </div>
      </div>
    )}
    <HomeBar></HomeBar>
  </Phone>
);

/* ============ DUA & TASBIH ============ */
const DUA_CATS = [
  ["sun", "Morning & evening", 24], ["food", "Food & drink", 11], ["moon", "Sleep & waking", 9],
  ["pin", "Travel", 13], ["home", "Home & family", 8], ["heart", "Distress & anxiety", 12],
  ["spark", "Forgiveness", 10], ["mosque", "Salah & masjid", 15],
];
const DuaHome = ({ dark }) => (
  <Phone dark={dark} time="7:20">
    <div style={{ padding: "6px 22px 0", display: "flex", alignItems: "center" }}>
      <span className="t-headline">Dua & dhikr</span><span style={{ flex: 1 }}></span>
      <QIcon name="search" size={21} color="var(--ink-2)"></QIcon>
    </div>
    <div style={{ flex: 1, padding: "16px 22px 0", minHeight: 0 }}>
      <div style={{ display: "flex", gap: 10, marginBottom: 16 }}>
        {[["beads", "Tasbih", "counter"], ["spark", "Asmaul Husna", "99 names"]].map(([ic, t, s]) => (
          <div key={t} style={{ flex: 1, padding: 16, borderRadius: "var(--r-lg)", background: "var(--primary)", color: "var(--on-primary)", position: "relative", overflow: "hidden" }}>
            <MotifBg opacity={0.07} cell={80}></MotifBg>
            <div style={{ position: "relative" }}>
              <QIcon name={ic} size={22}></QIcon>
              <div className="t-title-sm" style={{ marginTop: 10 }}>{t}</div>
              <div className="t-caption" style={{ opacity: 0.75 }}>{s}</div>
            </div>
          </div>
        ))}
      </div>
      <div className="t-label c-2" style={{ marginBottom: 10 }}>Collections</div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
        {DUA_CATS.map(([ic, t, n]) => (
          <div key={t} style={{ padding: 14, borderRadius: "var(--r-md)", background: "var(--surface)", border: "1px solid var(--line)" }}>
            <span style={{ width: 36, height: 36, borderRadius: 12, display: "grid", placeItems: "center", background: "var(--primary-soft)", color: "var(--on-primary-soft)" }}>
              <QIcon name={ic} size={18}></QIcon>
            </span>
            <div className="t-title-sm" style={{ fontSize: 14, marginTop: 9, lineHeight: 1.25 }}>{t}</div>
            <div className="t-caption c-3">{n} duas</div>
          </div>
        ))}
      </div>
    </div>
    <BottomNav active={3}></BottomNav>
  </Phone>
);

const DuaDetail = ({ dark }) => (
  <Phone dark={dark} time="7:21">
    <div style={{ display: "flex", alignItems: "center", padding: "6px 22px 0" }}>
      <QIcon name="back" size={22}></QIcon>
      <span className="t-title-sm" style={{ flex: 1, textAlign: "center" }}>Morning & evening · 3 of 24</span>
      <QIcon name="bookmark" size={20} color="var(--ink-2)"></QIcon>
    </div>
    <div style={{ flex: 1, padding: "18px 22px 0" }}>
      <div style={{ background: "var(--surface)", borderRadius: "var(--r-lg)", border: "1px solid var(--line)", padding: 20 }}>
        <div className="t-quran" style={{ fontSize: 26, lineHeight: 2.1, textAlign: "center", color: "var(--ink)" }}>
          أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ
        </div>
        <div className="t-caption" style={{ marginTop: 14, color: "var(--primary)", fontStyle: "italic", textAlign: "center" }}>
          Aṣbaḥnā wa aṣbaḥal-mulku lillāh, wal-ḥamdu lillāh
        </div>
        <div className="t-body c-2" style={{ marginTop: 12, textAlign: "center", fontSize: 14.5 }}>
          “We have entered the morning, and all sovereignty belongs to Allah. All praise is for Allah.”
        </div>
        <div className="t-caption c-3" style={{ marginTop: 12, textAlign: "center" }}>Muslim 2723 · morning, once</div>
      </div>
      <div style={{ display: "flex", justifyContent: "center", marginTop: 22 }}>
        <ProgressRing pct={1 / 3} size={120} color="var(--accent)">
          <div className="t-headline t-num" style={{ fontSize: 28 }}>1<span className="c-3" style={{ fontSize: 16 }}>/3</span></div>
          <div className="t-caption c-3" style={{ fontSize: 10 }}>tap to count</div>
        </ProgressRing>
      </div>
      <div style={{ display: "flex", gap: 16, justifyContent: "center", marginTop: 20, color: "var(--ink-3)" }}>
        <QIcon name="copy" size={18}></QIcon><QIcon name="share" size={18}></QIcon><QIcon name="reset" size={18}></QIcon>
      </div>
    </div>
    <HomeBar></HomeBar>
  </Phone>
);

/* ---- tasbih ---- */
const Tasbih = ({ dark, milestone }) => (
  <Phone dark={dark} time="9:50">
    <div style={{ display: "flex", alignItems: "center", padding: "6px 22px 0" }}>
      <QIcon name="back" size={22}></QIcon>
      <span className="t-title-sm" style={{ flex: 1, textAlign: "center" }}>Tasbih</span>
      <QIcon name="reset" size={20} color="var(--ink-2)"></QIcon>
    </div>
    <div style={{ display: "flex", gap: 8, justifyContent: "center", marginTop: 14 }}>
      <Chip active>33</Chip><Chip>100</Chip><Chip>Custom</Chip>
    </div>
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", position: "relative" }}>
      {milestone && <MotifBg opacity={0.07} cell={100} style={{ color: "var(--accent)" }}></MotifBg>}
      <div className="t-quran" style={{ fontSize: 22, color: "var(--ink-2)", marginBottom: 10 }}>سُبْحَانَ ٱللَّهِ</div>
      <ProgressRing pct={milestone ? 1 : 21 / 33} size={252} sw={13} color={milestone ? "var(--accent)" : "var(--primary)"}>
        <div className="t-num" style={{ fontSize: 84, fontWeight: 700, letterSpacing: "-3px", color: milestone ? "var(--accent-strong)" : "var(--ink)" }}>{milestone ? 33 : 21}</div>
        <div className="t-caption c-2">of 33</div>
      </ProgressRing>
      <div style={{ marginTop: 26, minHeight: 44, display: "grid", placeItems: "center" }}>
        {milestone ? (
          <span style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "11px 22px", borderRadius: 99, background: "var(--accent-soft)", color: "var(--on-accent-soft)", fontWeight: 700, fontSize: 14.5 }}>
            <QIcon name="spark" size={17}></QIcon>Set complete — round 2?
          </span>
        ) : (
          <span className="t-caption c-3">tap anywhere below the ring · haptic each count · pulse at 33</span>
        )}
      </div>
    </div>
    <div className="t-caption c-3" style={{ textAlign: "center", paddingBottom: 4 }}>Today · 3 sessions · 233 total</div>
    <HomeBar></HomeBar>
  </Phone>
);

/* ---- asmaul husna ---- */
const NAMES99 = [
  ["ٱلرَّحْمَـٰن", "Ar-Raḥmān", "The Most Compassionate"], ["ٱلرَّحِيم", "Ar-Raḥīm", "The Most Merciful"],
  ["ٱلْمَلِك", "Al-Malik", "The King"], ["ٱلْقُدُّوس", "Al-Quddūs", "The Most Holy"],
  ["ٱلسَّلَام", "As-Salām", "The Source of Peace"], ["ٱلْمُؤْمِن", "Al-Muʾmin", "The Giver of Faith"],
];
const AsmaulHusna = ({ dark }) => (
  <Phone dark={dark} time="8:05">
    <div style={{ display: "flex", alignItems: "center", padding: "6px 22px 0" }}>
      <QIcon name="back" size={22}></QIcon>
      <span className="t-title-sm" style={{ flex: 1, textAlign: "center" }}>Asmaul Husna · 99 names</span>
      <QIcon name="search" size={20} color="var(--ink-2)"></QIcon>
    </div>
    <div style={{ padding: "16px 22px 0" }}>
      <div style={{ borderRadius: "var(--r-lg)", padding: 20, background: "var(--primary)", color: "var(--on-primary)", position: "relative", overflow: "hidden", textAlign: "center" }}>
        <MotifBg opacity={0.07} cell={86}></MotifBg>
        <div style={{ position: "relative" }}>
          <div className="t-caption" style={{ opacity: 0.75 }}>№ 1</div>
          <div className="t-quran" style={{ fontSize: 40, lineHeight: 1.7 }}>ٱلرَّحْمَـٰن</div>
          <div className="t-title-sm">Ar-Raḥmān</div>
          <div className="t-caption" style={{ opacity: 0.8, marginTop: 2 }}>The Most Compassionate — mercy that embraces all creation</div>
        </div>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginTop: 12 }}>
        {NAMES99.slice(1).map(([a, t, m], i) => (
          <div key={t} style={{ padding: "13px 14px", borderRadius: "var(--r-md)", background: "var(--surface)", border: "1px solid var(--line)", textAlign: "center" }}>
            <div className="t-quran" style={{ fontSize: 23, color: "var(--primary)" }}>{a}</div>
            <div className="t-label" style={{ marginTop: 4, fontSize: 12.5 }}>{t}</div>
            <div className="t-caption c-3" style={{ fontSize: 10.5 }}>{m}</div>
          </div>
        ))}
      </div>
    </div>
    <HomeBar style={{ marginTop: "auto" }}></HomeBar>
  </Phone>
);

const SecQuranDua = () => (
  <React.Fragment>
    <DCSection id="quran" title="07 · Quran" subtitle="Mushaf-grade Uthmani type (KFGQPC HAFS) · resume card · independent font scale · night reading is first-class">
      <DCArtboard id="qr-list" label="Surah list + continue reading — Light" width={390} height={844}><SurahList></SurahList></DCArtboard>
      <DCArtboard id="qr-list-d" label="Surah list — Dark" width={390} height={844}><SurahList dark></SurahList></DCArtboard>
      <DCArtboard id="qr-first" label="First open · no bookmark yet" width={390} height={844}><SurahList firstOpen></SurahList></DCArtboard>
      <DCArtboard id="qr-empty" label="Search empty + suggestion" width={390} height={844}><SurahList searchEmpty></SurahList></DCArtboard>
      <DCArtboard id="qr-read" label="Reader · translation on — Light" width={390} height={844}><QuranReader></QuranReader></DCArtboard>
      <DCArtboard id="qr-read-d" label="Reader — Dark (night comfort)" width={390} height={844}><QuranReader dark></QuranReader></DCArtboard>
      <DCArtboard id="qr-aronly" label="Arabic-only mode — Dark" width={390} height={844}><QuranReader dark arOnly></QuranReader></DCArtboard>
      <DCArtboard id="qr-font" label="Reading settings sheet" width={390} height={844}><QuranReader fontSheet></QuranReader></DCArtboard>
      <DCArtboard id="qr-tab" label="Adapts · tablet 768 — two columns" width={768} height={844}><QuranReader w={768} h={844} cols={2}></QuranReader></DCArtboard>
    </DCSection>
    <DCSection id="dua" title="08 · Dua & Tasbih" subtitle="Daily-touch surfaces — tactile, quiet, beautiful">
      <DCArtboard id="d-home" label="Dua home — Light" width={390} height={844}><DuaHome></DuaHome></DCArtboard>
      <DCArtboard id="d-home-d" label="Dua home — Dark" width={390} height={844}><DuaHome dark></DuaHome></DCArtboard>
      <DCArtboard id="d-detail" label="Dua detail + repeat counter" width={390} height={844}><DuaDetail></DuaDetail></DCArtboard>
      <DCArtboard id="d-detail-d" label="Dua detail — Dark" width={390} height={844}><DuaDetail dark></DuaDetail></DCArtboard>
      <DCArtboard id="d-tasbih" label="Tasbih · mid-session — Light" width={390} height={844}><Tasbih></Tasbih></DCArtboard>
      <DCArtboard id="d-tasbih-d" label="Tasbih — Dark" width={390} height={844}><Tasbih dark></Tasbih></DCArtboard>
      <DCArtboard id="d-tasbih-m" label="Tasbih · milestone pulse at target" width={390} height={844}><Tasbih dark milestone></Tasbih></DCArtboard>
      <DCArtboard id="d-asma" label="Asmaul Husna · browse + featured" width={390} height={844}><AsmaulHusna></AsmaulHusna></DCArtboard>
      <DCArtboard id="d-asma-d" label="Asmaul Husna — Dark" width={390} height={844}><AsmaulHusna dark></AsmaulHusna></DCArtboard>
    </DCSection>
  </React.Fragment>
);

window.SecQuranDua = SecQuranDua;
