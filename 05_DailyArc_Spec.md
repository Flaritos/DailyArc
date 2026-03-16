# DailyArc — Habit + Mood Tracker (Revised v31)

## Quick Navigation (5,200+ lines — use these anchors)

### BUILD SPEC (Developer's daily reference)
- [Architecture Overview](#architecture-overview) — Line ~110
- [Data Model](#data-model) — Line ~245
- [Project Structure](#project-structure) — Line ~900
- [Navigation Architecture](#navigation-architecture) — Line ~1020
- [Screen-by-Screen UI](#screen-by-screen-ui-specification) — Line ~1070
- [RuleEngine](#ruleengine-servicesruleengineswift--only-copy) — Line ~1815
- [StreakEngine](#streakengine-servicesstreakengineswift) — Line ~1915
- [DebouncedSave](#debouncedsave-utilitiesdebouncedsaveswift) — Line ~2150
- [HealthKit Integration](#healthkit-integration-serviceshealthkitserviceswift) — Line ~2295
- [Correlation Engine](#correlation-engine-servicescorrelationengineswift) — Line ~2475
- [Build Step Sequence](#claude-code-build-step-sequence) — Line ~2810
- [Milestone Checklist](#milestone-checklist) — Line ~3880

### LAUNCH SPEC (Pre-launch and post-launch)
- [Pre-Launch Checklist](#pre-launch-checklist) — Line ~4390
- [TestFlight Go/No-Go](#testflight-gono-go-criteria) — Line ~4450
- [Development Timeline](#development-timeline-realistic) — Line ~4480
- [Privacy Policy](#privacy-policy-template-required-for-app-store-submission) — Line ~4570
- [Terms of Service](#terms-of-service--eula-required-for-iap-apps) — Line ~4615
- [Post-Launch Monitoring](#post-launch-monitoring-plan) — Line ~4630
- [Risk Register](#risk-register) — Line ~4890
- [App Store Optimization](#app-store-optimization) — Line ~4170

### BRAND & MARKETING SPEC
- [Brand Guidelines](#brand-guidelines) — Line ~3900
- [Target Personas](#target-user-personas) — Line ~4015
- [Content Calendar](#content-calendar--marketing-strategy-pre-launch--week-12) — Line ~4095
- [Growth Experiments](#growth-experiment-framework) — Line ~4740
- [Instagram Strategy](#appendix-a-instagram-marketing-strategy) — Line ~4970
- [Reddit Strategy](#appendix-b-reddit-community-strategy) — Line ~5000

### APPENDICES
- [CloudKit Readiness](#appendix-c-cloudkit-readiness-assessment) — Line ~5045
- [visionOS/macOS Roadmap](#appendix-d-visionos--macos-compatibility-roadmap) — Line ~5080
- [AI Integration Roadmap](#appendix-e-ai-integration-roadmap) — Line ~5100
- [Monitoring & Alerting](#appendix-f-automated-monitoring--alerting) — Line ~5125
- [TelemetryDeck Cost Model](#appendix-g-telemetrydeck-cost-model) — Line ~5165
- [Global Analytics Properties](#appendix-h-global-analytics-properties) — Line ~5190

---

> **v31 revision notes (perfection push — targeting all 13 active agents at 9.0+, from v30 avg 8.81):**
> **Architecture reconciliation (Mobile, Backend, Perf — 3 agents):** HealthKitModelActor code block marked LEGACY with explicit "do NOT implement as separate actor" warning — all references redirected to HabitLogWriteActor; merge policy section updated to reflect single-writer architecture; escape hatch plan replaced with "no longer needed" note; HealthKitModelActor lifecycle section rewritten for HabitLogWriteActor. **Navigability (PM, UXA — 2 agents):** "See also" cross-reference blocks added to ALL 10 build steps (not just Step 5b); iPad width contradiction resolved (390pt reference updated to cite rule 19b's 500pt as authoritative); deferred banner persistence mechanism defined (`@AppStorage("deferredBanners")` JSON); quiet middle cards and monthly reflection added to banner priority order. **Timeline realism (PM):** Week 0 pre-launch added; research recruitment lead times embedded inline (Week 3 for usability, Week 10 for influencer outreach, Week 12 for accessibility tester, Week 13 for translations); DPIA completion moved to Week 4; rapid prototype test added to MVP Decision Gate as BLOCKING. **Performance:** Cold launch budget arithmetic reconciled (<500ms critical path + ~600ms concurrent deferred = <1.1s total, not <1.0s); clarified that <1.0s refers to interactive TodayView, deferred extends to 1.5s. **UX Research:** Cross-cultural recruitment specifics added (UserTesting.com panels, $450-1,125 budget, local-language sessions); interview failure criteria with 60% threshold for BLOCKING design changes; diary study compensation reconciled ($25, over-recruit 50%). **Growth:** Pre-registration landing page (dailyarc.app/launch via Buttondown, Week -6); paid acquisition $300 cap before 90-day review; influencer seeding strategy (10-20 micro-influencers, outreach template, TestFlight beta sharing). **Social:** Influencer seeding added to Reddit appendix. **Backend:** DataCompactionService.swift and BackgroundTaskService.swift added to project file tree; SchemaV1 models noted for DailySummary inclusion in Step 1 code.
>
> **v30 revision notes (targeting all 14 agents at 9.0+, from v29 avg 8.40):**
> **Cross-agent fixes (3+ agents):** (1) All remaining unqualified "data never leaves" claims fixed: Brand Positioning Statement, App Store long description, CCPA disclosure, data consent summary, localized descriptions (DE/JP/PT-BR) — now consistently say "habit and mood data stays on your device" with Buttondown exception disclosed (Legal, Brand, ASO); (2) HabitLogWriteActor code definition added with `saveLog()`, `saveMood()`, `commitPendingChanges()` API — DebouncedSave code block reconciled to dispatch to write actor (Mobile, Backend, Perf); (3) DedupService "fetch all" in Step 8 integration fixed to 30-day scope, skip interval aligned to <1 hour consistently (Backend, Perf); (4) AccessibilityEnvironment code block expanded with `isDifferentiateWithoutColorEnabled`, VoiceOver mapping clarified (`accessibilityEnabled` covers all AT — acceptable behavior documented), HealthKit `UIApplication.shared` replaced with `BackgroundTaskService` protocol + full code definition (visionOS, Mobile). **UX Research (targeting +1.5):** Personas rewritten with Jobs-to-Be-Done, current behavior, switching triggers, anxieties; pre-launch validation plan added (5-8 interviews during TestFlight beta, BLOCKING); rapid prototype test at MVP Week 5 (BLOCKING for onboarding changes); cross-cultural UX research plan for DE/JP/PT-BR; monitoring threshold sample size requirements added. **Growth:** Deferred deep link strategy for v1.1 referral; 90-day mandatory revenue model review; notification permission timing flagged as A/B test candidate. **Social/Brand:** Crisis communication protocol with 3 tiers and pre-drafted responses; Brand Voice Matrix expanded with Social/Twitter, Reddit, Email registers; CCPA Buttondown service provider exemption added. **PM:** Build Step 5b cross-reference list added; pre-launch checklist cross-references to Phase system. **UXA:** Banner collision matrix for 3+ qualifying banners; offline behavior section added; returning-after-absence clarified as greeting variant not banner. **UI:** iPad minimum viable presentation (500pt max-width); `deviceModelIdentifier()` implementation added (POSIX, cross-platform). **Whimsy:** Days 30-100 quiet middle touchpoints added (Day 45/60/75/90 + monthly reflection card). **ASO:** Localized descriptions updated to remove "never leaves" phrasing. **Backend:** SchemaV1.models array updated to include DailySummary.self; DataCompactionService file-tree entry noted.
>
> **v29 revision notes (P1 fixes from v28 re-audit, avg 8.23/10 → targeting 8.5+):**
> **Consensus fixes (2+ agents):** (1) DebouncedSave code block reconciled with HabitLogWriteActor: `triggerImmediate()` method added to code block, usage pattern updated with streak-critical conditional, `performSave()` documented as dispatching to write actor not direct `context.save()` (Mobile, Perf, Backend); (2) Marketing copy "data never leaves" qualified to "habit and mood data" across App Store description, release notes, brand positioning, AI principles — prevents misleading privacy claims post-email-collection (Legal, Brand); (3) Pre-launch checklist reorganized into 4 phases (Week 0 / Week 5 / Week 14 / Week 17-18) with lead-time warnings for DPIA, accessibility recruiting, trademark filing, translation (PM, Legal); (4) Twitter/X Strategy appendix added (Appendix A2) with 4 content pillars, 5x/week cadence, thread templates, engagement tactics, monthly KPIs with action thresholds (Social, Brand); (5) DedupService scope fixed to 30-day window consistently — removed contradictory "fetch all" references, aligned with HabitLogWriteActor single-writer architecture (Perf, Backend). **Single-agent fixes:** (6) NavigationPath Codable destination enums defined (TodayRoute, StatsRoute, SettingsRoute) using UUID not PersistentIdentifier (Mobile); (7) DailySummary model upgraded from pipe-delimited to JSON-encoded dictionary, added to SchemaV1.models, #Index on date, idempotency check (Backend); (8) DataCompactionService transactional safety: per-date atomic save, oldest-first processing, DailySummary existence check (Backend); (9) `isDifferentiateWithoutColorEnabled` migrated to SwiftUI environment per rule 39b (visionOS); (10) StreakEngine cold-launch reconciliation added as named task #5 in launch TaskGroup, TaskGroup cancellation semantics clarified (Perf); (11) AccessibilityEnvironment helper expanded with `isDifferentiateWithoutColorEnabled` property (visionOS).
>
> **v28 revision notes (10 P0 fixes from 14-agent audit, avg 7.41/10):**
> **Consensus fixes (3+ agents):** (1) CRITICAL: App Store nutrition labels updated to declare email collection, privacy policy corrected ("data never leaves device" → exception for email/Buttondown), email marketing consent toggle added per GDPR/ePrivacy, Buttondown DPA required as blocking prerequisite (Legal, Brand, Growth); (2) UIKit→SwiftUI accessibility migration: all `UIAccessibility.isReduceMotionEnabled` → `@Environment(\.accessibilityReduceMotion)` via `AccessibilityEnvironment` helper, `UIAccessibility.isVoiceOverRunning` → `@Environment(\.accessibilityEnabled)`, `UIDevice.current.systemVersion` → `ProcessInfo.processInfo.operatingSystemVersionString` — enables visionOS/macOS portability (visionOS, Mobile, Perf); (3) Dual-context write race eliminated: ALL HabitLog/MoodEntry writes routed through single `HabitLogWriteActor` @ModelActor, main context read-only for logs, automated circuit breaker at 0.5% dedup rate (Backend, Mobile, Perf, UX Arch); (4) Cold launch per-task timeouts: 500ms individual cap with `withTimeout` wrapper, 1.5s total group budget, per-task fallback behavior specified, alert threshold aligned to 2.0s budget (Perf, Mobile); (5) Quick Navigation TOC added (BUILD/LAUNCH/BRAND sections) to reduce cognitive overhead of 5,200+ line spec (PM, UX Arch, Mobile); (6) Instagram strategy reconciled with channel analysis: reduced to Month 3+ stretch channel, daily Stories dropped, cadence cut to 2 posts/week, 60-day kill threshold added (Growth, Social, Brand); (7) Data retention policy added: 365-day full-resolution window, DailySummary compaction model for historical data, DataCompactionService via BGAppRefreshTask (Backend, Perf, Mobile); (8) CorrelationEngine habit cap: top 10 most-recently-active habits processed within SLA, remainder scheduled as background retry (Backend, Perf, Mobile). **Single-fix items:** (9) DebouncedSave attoseconds→milliseconds conversion fixed (was dividing by 10^12 instead of using Duration division) (Perf); (10) iCloud Drive backup WAL checkpoint added before SQLite copy — prevents backups missing recent writes (Backend).
>
> **v27 revision notes (~120 fixes from 43-agent full-roster audit, avg 6.9/10):**
> **Consensus fixes (5+ agents):** Orientation contradiction resolved (rule 19b aligned with rule 35 portrait-lock); timeline extended from 9-11 weeks to 14-18 weeks with Step 1/6 splits; Instagram Stories share card format (1080x1920) added; branded hashtag #MyDailyArc added; Reddit strategy expanded from quarterly to daily engagement with 6-week pre-launch plan; social/viral strategy overhauled across Instagram, Reddit, TikTok. **Infrastructure fixes (3-4 agents):** CI/CD elevated to Day 1 prerequisite (rule 37); Xcode 16/Swift 6 version pinning added (rule 36); on-device iCloud Drive backup mechanism added (rule 39); CloudKit readiness assessment section added; Day 14 insight teaser card added for pre-activation engagement. **Technical fixes (2-3 agents):** Analytics event taxonomy expanded (+15 events); feature adoption KPIs added; PPO test p-values standardized to p<0.05 two-tailed; A/B experiment interaction controls and guardrail metrics added; hypothesis statements added to all 4 experiments; heat map Canvas degradation strategy added; CorrelationEngine Accelerate framework migration noted; widget circuit breaker added; cold launch task ordering specified; SwiftData escape hatch plan documented; breach notification HMAC integrity added. **New sections:** Instagram Marketing Strategy; Reddit Community Strategy; CloudKit Readiness Assessment; visionOS/macOS Compatibility Roadmap; AI Integration Roadmap; Automated Monitoring & Alerting; TelemetryDeck Cost Model; Global Analytics Properties. **Process fixes:** In-app help system (15+ FAQ articles); onboarding re-play; streak recovery transparency; error state Contact Support CTAs; destructive action data counts; device transfer guidance; widget troubleshooting guide; post-launch triage priority; minimum shippable product definition; scope freeze operationalization with effort estimates; sound design marked P2; email backend (Buttondown) specified; revenue expansion path documented.
>
> **v26 revision notes (~40 fixes from v25 audit, avg 8.83):**
> **4-agent consensus (2 fixes):** A/B test sample sizes annotated with feasibility triage and indie-realistic timelines; email collection UI fully specified in onboarding Page 3 (field, copy, positioning, opt-in target). **3-agent consensus (8 fixes):** `habitIDDenormalized` added to HabitLog property table + `$0.habit?.id` fixed to `$0.habitIDDenormalized` in `weeklyCompletions` and `applyRecovery`; share card dimension canonicalized to 1080×1350 (4:5) for Instagram, 1200×630 for Twitter; energy picker 44pt sizing clarified as intentional secondary hierarchy (removed "matching mood picker pattern" contradiction); DedupService `Dictionary(grouping:)` reference removed from Data Model section (sorted-walk is sole algorithm); `WidgetCenter.shared.reloadAllTimelines()` added after widget data write; landscape/portrait contradiction resolved (line 684 removed, portrait-only declared); navigation transition animations added to animation table; streak recovery banner copy fixed ("Missed" → compassionate rewrite per anti-terms). **2-agent consensus (16 fixes):** `LogKey` struct defined in DedupService; `streakRecoveryAvailable` upgraded from pseudocode to full implementation; Explorer→Detail Arc rename fixed in Settings whimsy; skeleton blueprints added for BadgesView/PerHabitDetailView; pressed state mapping table added; Comeback Arc + 365-day arc animations added to animation table; D14 retention alert added to Week 1 Dashboard; returning-after-absence + re-engagement mutual exclusion added; `WidgetDataService.writeNow` mood query filtered to today; content KPI action thresholds added; line-height/letter-spacing tokens added to typography; AX5 specs added for HabitFormView and badge ceremony modals; Today View max-banner rule added (max 2 concurrent); financial model section added; priority tiers (P0/P1/P2) added to build Steps 5-8; NavigationPath state restoration + deep link error handling added; arc metaphor saturation ceiling defined (max 3/screen, 5/session); activation metric secondary definition for habit-only users added; lightweight v1.0 referral surface added; contrast ratio verification table added; `WidgetPayload` decode-fallback strategy added; `displaySmall` `.leading(.tight)` added; `computeBestStreak` offloaded from @MainActor for deletion path; data integrity validator added; supported device classes explicitly declared; tag chip "+" cancel affordance added; emoji usage guideline added; brand copy audit checklist added; "Honest" trait added; scope freeze rule added.
>
> **v25 revision notes (~55 fixes from v24 audit, avg 8.69):**
> **4-agent consensus (3 fixes):** `habitIDDenormalized` explicitly declared as stored property on HabitLog model (was referenced but never declared — compile-blocking); `@Sendable` annotation added to ALL `Task.detached` code samples (mandate existed but examples contradicted it); DedupService algorithm canonicalized to sorted-walk only — removed contradictory `Dictionary(grouping:)` with non-Hashable tuple key from project structure comments. **3-agent consensus (8 fixes):** Widget whimsy added (seasonal variants, "All done!" micro-copy, arc-themed placeholders); sound design contradiction resolved — Design Tokens section is authoritative (.caf, 4 sounds), Whimsy section updated to cross-reference; UGC v1.0 testimonial collection mechanism added (30-day in-app prompt + permission capture); Day 14 retention cohort target added (≥15%) with insight-unlock-specific remediation; `beginBackgroundTask` rewritten with `await MainActor.run {}` pattern for Swift 6 `UIApplication.shared` isolation; CorrelationEngine partial-results contract fully specified (UI indicator, follow-up task, "not yet computed" distinction); automated XCTest performance regression tests added (PerformanceTests target with `measure {}` blocks); DedupService tuple key fixed (uses `LogKey: Hashable` struct). **2-agent consensus (14 fixes):** Energy-habit correlation now computes full Pearson pipeline with `skipDayEnergyValues` comparison group; `@AppStorage` in StreakEngine replaced with `UserDefaults.standard`; post-Week-12 recurring monthly content calendar template added; email drip segmentation added (free/premium branches, premium onboarding email, sunset sequence); calendar picker visual affordance added (small calendar icon beside date label); returning-after-absence greeting variants added (2+ week gap detection); Settings screen whimsy added (version number 7-tap Easter egg, personality in About section); competitive UX audit expanded with Nielsen heuristic scores and task-level comparison data; customer support expanded (SLA, escalation path, 8-topic FAQ, App Store Connect phased rollout); content performance KPIs added (blog traffic, email open rate, social engagement targets); share card recipient CTA added ("See your own patterns" + dailyarc.app landing page); `MoodEntry.fetchOrCreate` now requires `calendar:` parameter; `WidgetDataService.writeNow` filters `todayLogs` by active habit IDs; illustration style guide expanded with compositional rules (negative space, grid, arc placement, scaling). **Single-agent fixes (~30):** Confidence interval Swift code block added (Fisher z-transformation); Cornish-Fisher lookup table expanded for Bonferroni-corrected alpha values (0.025, 0.01, 0.005); A/B test decision criteria clarified (N is analysis point, p-value checked at N); effect size thresholds explicitly labeled as Cohen's d equivalents; cancellation check added inside inner moodByDate loop (every 50 iterations); moodScore range validation (1-5 clamp); `Font.leading(.tight)` conditional on scaled size below AX3 threshold; `WidgetPayload` shared target instruction explicit in build step; `streakRecoveryAvailable` pseudocode implementation added; `DebouncedSave.onError` annotated `@Sendable`; deferred task bundle sequencing strategy (serial TaskGroup, `.utility` priority); thermal state monitoring with adaptive degradation; per-screen skeleton loading blueprints added; SF Symbol token catalog added; spacing scale extended (xxxl 48pt, jumbo 64pt); toast queueing behavior defined (serial queue, newest replaces); landscape/iPad statement added; dark mode widget guidance added; pressed/active state component mapping added; share card fixed rendering mode (always branded, not system appearance); custom component accessibility labels specified (CompletionCircle, heat map cells); anti-term code comments fixed ("streak needs attention", "action incomplete"); brand voice audit for journaling prompts (60/30/10 ratio guideline); weekend greeting rewritten ("your arc is here whenever you are"); Explorer badge reframed as passive acknowledgment (no counter/tracker); notification streak-loss copy added to Brand Voice Matrix; brand evolution measurement KPIs added; loading state copy variants expanded (3 per context); BadgesView empty state personality copy added; non-celebration micro-interaction sounds noted for v1.1; Settings sound Easter egg specified; returning-user greeting for 2+ week absence; diary study compensation ($75 gift card) and dropout mitigation (over-recruit 50%); persona validation success/failure criteria defined; Fogg diagnostic instrumentation (proxy metrics for motivation/ability/prompt); SUS questionnaire added to usability protocol; 21-day myth replaced with "habits take time" (Lally et al. citation); D14 retention target added; `user_activated` analytics event added; activation recovery notifications extended to Days 4-6; feature flag cleanup lifecycle specified; App Store Connect phased rollout added as primary rollback; risk register ownership + monthly review cadence; PPO 90-day wait corrected (no Apple restriction); Apple Search Ads negative keyword list added; In-App Event card copy fields specified; LGPD Art. 14 age threshold implementation clarified with geo-detection note; APPI cross-border transfer cites PPC EU adequacy decision; COPPA 30-day rounding documented as accepted risk; MetricKit LIA referenced in DPIA; TTDSG Keychain justification for DOB writes documented; privacy policy effective date format specified (ISO 8601).

## Composite Score: Target 50/50 | Realistic Build: 14–18 Weeks (MVP at Step 4: 4–5 Weeks)

**Tagline:** See how your habits shape your mood.
**Tagline hierarchy:** Primary (marketing/ASO/App Store): "See how your habits shape your mood." Secondary (in-app/onboarding emotional throughline): "Every day adds to your arc." Use primary in all external-facing contexts. Use secondary for onboarding Page 1 and share cards.
**Market context:** Habit trackers (Daylio, Streaks, Habitify) and mood trackers (Daylio) are separate categories. DailyArc unifies them — the only habit tracker that connects what you do to how you feel, entirely on-device.
**Monetization:** One-time purchase — display `product.displayPrice` (configured as $5.99 USD in App Store Connect; never hardcode price strings for international compliance)
**Minimum iOS:** 17.4 (required for `#Index` macro; 17.0–17.3 users are <2% of iOS 17 installs)

> **Revision Notes (v23):** ~55 fixes from v22 14-agent audit (avg 7.87). **Cross-agent consensus fixes (4+ agents):** (1) `Calendar.current` default removed from `DateHelpers.shouldAppear` — `calendar:` parameter now required (no default) across ALL call sites: Habit.shouldAppear, HabitLog.fetchOrCreate, MoodEntry.fetchOrCreate, DaySnapshot.snapshots, WidgetDataService, RuleEngine (AI Eng, Mobile, Backend, Perf). **3-agent consensus fixes:** (2) StreakEngine: removed redundant `: Sendable` (already implied by @MainActor), cold-launch budget enforced (AI Eng, Backend, Perf), (3) Phase 1 markets realigned: FR/ES deferred to Phase 2, PT-BR added (higher iOS revenue, lower ASO competition) — all localization tables, keywords, descriptions, screenshot overlays, promotional text, privacy policy, and EU consent age gates updated (ASO, Content, Growth), (4) Global celebration budget + paywall mutual exclusion enforced (UX Arch, Growth, Brand). **2-agent consensus fixes:** (5) Onboarding Page 1 two-step progressive disclosure (UX Arch, UX Research), (6) Widget premium blur → solid placeholder (UI Design, UX Arch), (7) Widget empty/error/first-launch states with arc-themed copy: "Start your arc" / "Continue your arc" (Mobile, UX Arch), (8) Greeting variants: streak-aware, day-of-week, seasonal, rare 1-in-30 probability (Whimsy, Brand), (9) Sound design production specs with frequency/ADSR/dB (Brand, UI Design), (10) A/B test sample sizes pre-computed per experiment (Growth, PM), (11) Graduated streak loss copy in 4 tiers (Content, UX Research), (12) WidgetDataService habitsDone uses `count >= targetCount` (Backend, Mobile), (13) Streak check-in notification copy compassionately rewritten: "Pick up where you left off" replaces "Yesterday was a full day" (Content, UX Research). **High-impact single-agent fixes:** (14) Build Step 6 DOB storage: `@AppStorage` → Keychain via `KeychainService.setDOB(month:year:)` for reinstall protection (Legal), (15) `@AppStorage("parentalConsentDate")` → Keychain for consistency (Legal), (16) GDPR consent hash versioning: `gdprConsentVersion` stores SHA256 hash of consent text, re-prompts on policy change (Legal), (17) LGPD compliance section added to Privacy Policy for Brazil Phase 1 market, Art. 14 children's consent for under-18 (Legal), (18) Brand anti-terms glossary: 10 banned terms with alternatives ("Don't break your streak!" → "Keep building your arc") (Brand), (19) Brand personality traits formalized: Warm, Insightful, Patient, Minimal, Empowering (Brand), (20) "Show streaks" toggle in Settings: hides all streak UI for pressure-free logging mode (UX Research), (21) Fogg Behavior Model mapping: B=MAP loop mapped to DailyArc's Trigger→Action→Reward→Investment cycle (UX Research), (22) 14-day diary study protocol: 8-12 participants, daily Typeform, Day 15 exit interview, validates motivation valley hypothesis (UX Research), (23) Retention cohort targets: D1≥40%, D7≥20%, D30≥12%, D90≥8% with action thresholds (PM), (24) Energy score insights expanded: day-of-week pattern, energy-habit correlation, trend sparkline (AI Eng), (25) DedupService algorithm explicit: sort by (habitIDDenormalized, date), single-pass walk, keep max count, <200ms budget (Backend), (26) Schema fingerprint test: assert VersionedSchemaV1 property snapshot matches committed file (Backend), (27) Timezone change behavior expanded: DST, International Date Line edge cases documented (Backend), (28) MVP decision gate at Week 4: usability test, performance, stability go/no-go criteria (PM), (29) Activation metric aligned: requires habit 3-of-7 days AND at least 1 mood log (Growth, PM), (30) In-App Events strategy: 4-6 seasonal events per year for Store visibility (ASO), (31) Custom Product Pages: 3 CPPs targeting mood/streak/privacy intents (ASO), (32) Product Page Optimization: 3 A/B tests for screenshots, icon, subtitle (ASO), (33) App Preview Video shot list expanded: 6 shots, 25 seconds, device audio only (ASO), (34) Content calendar: 12-week pre-launch→post-launch marketing plan with channel/content/goal (Content), (35) German subtitle loanwords fixed: "Statistik"→"Statistiken", "Wellness"→"Wohlbefinden" (ASO), (36) Japanese subtitle expanded: "記録・統計・セルフケアログ" with マインドフルネス removed from keywords (ASO), (37) DebouncedSave save-criticality tiers: `triggerImmediate()` for streak-changing, mood, recovery events (Backend), (38) HealthKitModelActor.createOrUpdateLog passes calendar, sets habitIDDenormalized, preserves isAutoLogged (Mobile), (39) NotificationCenter observer changed to `.task` modifier pattern (Backend), (40) CorrelationEngine extractSnapshots uses `habitIDDenormalized` instead of `$0.habit?.id` to avoid N+1 faults (Perf), (41) Typography displayLarge aligned: 42pt in both table and @ScaledMetric ViewModifier (UI Design), (42) RuleEngine duplicate rule renumbered, gamification language replaced with arc metaphor (Brand), (43) Today View header: visual arc progress indicator (270° arc) replaces numeric badge (UI Design), (44) Completion ring flash/glow animation on targetCount (Whimsy), (45) Paywall reduced from 8 to 5 triggers per Calm brand value (Brand), (46) Celebrations trimmed to 6 v1.0 tiers (3/7/14/30/100/365), deferring 60/500/1000 to v1.1 (PM), (47) Comeback Arc: 3 message variants + broken arc reconnection animation (Whimsy), (48) Badge ceremony tiered: Starter (inline), Milestone (modal+glow), Summit (confetti+arc), Zenith (particles) (Whimsy), (49) Day 1-2 micro-delights, Day 8/12/25 touchpoints (UX Research), (50) Journaling prompts expanded to 30+ with arc-metaphor, habit-aware, temporal categories (Content), (51) Easter egg Explorer badge with 5/8 discovery threshold (Whimsy), (52) Share card visual specs per tier (7-day white, 30-day gradient, 100-day gold, 365-day premium) (UI Design), (53) `habitIDDenormalized` populated in all HabitLog creation paths (Backend), (54) DaySnapshot.snapshots uses habitIDDenormalized for O(1) lookup (Perf), (55) Onboarding value props rewritten with arc metaphor + implementation intentions (UX Research).
>
> **Revision Notes (v22):** ~28 fixes from v21 14-agent audit (avg 8.00). **Cross-agent consensus fix (1 issue, 4 agents):** (1) `Calendar.current` eliminated from `Habit.shouldAppear`, `HabitLog.fetchOrCreate`, `MoodEntry.fetchOrCreate`, and `DateHelpers.shouldAppear` — all now accept `calendar: Calendar` parameter, matching CorrelationEngine/RuleEngine/StreakEngine pattern (AI Engineer, Mobile Builder, Backend Architect, Performance Benchmarker). **3-agent consensus fixes (3 issues):** (2) StreakEngine: added `Sendable` conformance, `nonisolated init()` for @State, 200ms cold-launch reconciliation budget via `ContinuousClock`, all `shouldAppear` calls pass calendar parameter (AI Engineer, Backend Architect, Performance Benchmarker), (3) Localized notification copy: Phase 1 market translations required for 4+ variants per notification type (evening/mood/weekly/reactivation), Easter egg and journaling prompt `String(localized:)` wrappers added (Content Creator, ASO Specialist, Brand Guardian), (4) Global celebration/notification budget: max 3 celebration events per session with deferred queue, paywall triggers #4/#8 mutually exclusive with celebrations to preserve emotional moments (UX Architect, Growth Hacker, Brand Guardian). **2-agent consensus fixes (10 issues):** (5) Onboarding Page 1 two-step progressive disclosure: value props visible first, "Continue" reveals age/consent section — two cognitive chunks instead of content wall (UX Architect, UX Researcher), (6) `mutating` removed from `MoodEntry.addActivity` — `@Model class` methods cannot be `mutating` (Mobile Builder, AI Engineer), (7) Widget premium blur replaced with solid placeholder card consistent with Insights teaser pattern (UI Designer, UX Architect), (8) Widget empty/error/first-launch states: "Open DailyArc to get started", last-known-good cache fallback, `.redacted(reason: .placeholder)` for system shimmer (Mobile Builder, UX Architect), (9) Arc metaphor in daily greetings: streak-aware, day-of-week, and seasonal variants with priority selection (Whimsy Injector, Brand Guardian), (10) Sound design production specs: frequency/ADSR/dB table for all 4 sounds, .caf format, <100KB total (Brand Guardian, UI Designer), (11) A/B testing sample size: pre-computed N per variant per experiment using G*Power-equivalent, sequential analysis spending function, decision rule against early stopping (Growth Hacker, Senior PM), (12) Graduated streak loss copy: 4 tiers (short 3-6, medium 7-29, long 30-99, epic 100+) with scaled card intensity and Comeback Arc prompt for epic losses (Content Creator, UX Researcher), (13) `WidgetDataService.habitsDone` uses `count >= targetCount` instead of `count > 0` — multi-count habits now correctly tracked (Backend Architect, Mobile Builder), (14) `shouldAppear` calls in `WidgetDataService.weeklyCompletions` pass `calendar:` parameter (Backend Architect, Mobile Builder). **High-impact single-agent fixes (14 issues):** (15) Typography `DailyArcTypography` changed from enum to struct with `@ScaledMetric` for display sizes — displayLarge (42pt), displayMedium (36pt), displaySmall (32pt) are now visually distinct (UI Designer), (16) Confetti particle spec reconciled: Architecture Decision 30 updated to match authoritative Celebration Intensity spec (60% rect/30% circle/10% emoji, gravity 600pt/s²) (UI Designer), (17) `ModelContainer` initializer corrected from `Schema(versionedSchema:)` to `ModelContainer(for: DailyArcSchemaV1.models, ...)` (Mobile Builder), (18) VersionedSchema `#Index` macros placed inside enum scope as actual declarations (not comments) (Backend Architect), (19) RuleEngine `generateSuggestions` uses `Dictionary(grouping:)` pre-grouping for O(L+H) instead of O(H*L) filter-per-habit (Performance Benchmarker), (20) Bonferroni denominator changed from `raw.count` to `habits.count` — total input habits, not just those passing class imbalance guard (AI Engineer), (21) DebouncedSave `userCalendar` re-capture wired to `.onChange(of: scenePhase) .active` (Backend Architect), (22) TodayView usage: `fetchOrCreate` and `recalculateStreaks` now pass captured calendar from `debouncedSave?.userCalendar` (Mobile Builder), (23) `autosaveEnabled = false` promoted from comment to mandatory build step instruction (Backend Architect), (24) `nonisolated init()` added to TodayViewModel and StatsViewModel for Swift 6 @State compatibility (Mobile Builder), (25) DPIA timing: must complete before Step 5b (Week 4 MVP cut), not just before launch (Legal Compliance), (26) Art 21 objection mechanism for MetricKit: Settings → Privacy → "Crash Reporting" toggle with `MXMetricManager` unsubscribe (Legal Compliance), (27) Interactive Easter eggs: 5-tap icon on onboarding, long-press 50+ streak fire, shake gesture on Stats tab (Whimsy Injector), (28) `isSignificant` function: small-sample lookup table (df 12-30) added before Cornish-Fisher analytical path for improved accuracy (AI Engineer).
>
> **Revision Notes (v21):** ~20 fixes from v20 14-agent audit (avg 7.93). **Cross-agent consensus fix (1 issue, 3 agents):** (1) `HealthKitModelActor.createOrUpdateLog` now takes `calendar: Calendar` parameter — eliminates `Calendar.current` on non-main actor, matching CorrelationEngine/RuleEngine/StreakEngine pattern (AI Engineer, Mobile Builder, Backend Architect). **2-agent consensus fixes (9 issues):** (2) Full localized App Store descriptions required for all Phase 1 markets (DE/JP/FR/ES) — not just opening paragraph; professional translation budgeted (Content Creator, ASO), (3) Deep link routing table added with URL→action mapping, malformed URL handling, and onboarding guard for pre-completion deep links (UX Architect, Growth Hacker), (4) `DailyArcTypography` changed from enum with fixed-size fonts to `ViewModifier` using semantic SwiftUI font styles — all cases now scale with Dynamic Type natively (Mobile Builder, UI Designer), (5) A/B test activation timeline specified: Experiment 1 at Week 2-3 (~500 installs), Experiments 2-3 at Week 6-8, Experiment 4 at Week 10-12; decision criteria (p<0.05 + 10% practical significance) and minimum sample guards (Growth Hacker, Senior PM), (6) Sonic brand guidelines added: C major pentatonic key center, marimba timbre, ascending major 3rd/5th intervals; completion pop pitch shifts per consecutive tap within session for variable reward (Brand Guardian, Whimsy), (7) Confetti particle specs fully defined: size 8-14pt, shape mix (60% rect/30% circle/10% emoji), brand palette colors, velocity/gravity/rotation/fade constants, dark mode opacity 0.85 (UI Designer, Whimsy), (8) Widget data changed from untyped `[String: Any]` + `JSONSerialization` to `WidgetPayload: Codable, Sendable` struct shared between app and widget extension — compile-time schema safety (Backend Architect, Mobile Builder), (9) Consent withdrawal UI now disables all input controls immediately (`.disabled(true)` on habit taps, mood picker hidden) — prevents silent data loss from performSave() guard skipping saves on data the user thought was captured (Legal, Content Creator), (10) Notification copy variants expanded: evening reminders 4→15, mood reminders 4→12, weekly summary 3→8 (including low/zero-activity variants) — prevents notification blindness from 4-day repetition cycle (Content Creator, UX Researcher). **High-impact single-agent fixes (10 issues):** (11) RuleEngine duplicate `Suggestion` struct removed — second definition (habitID, message, priority) deleted, keeping first (emoji, text, priority) which matches all call sites (AI Engineer — compile blocker), (12) Bonferroni denominator now captured before display filter: `testedCount = raw.count` before `.filter { sampleSize >= 14 }`, preventing anti-conservative correction (AI Engineer), (13) Cold-launch streak reconciliation added: TodayView.task { } verifies all cached streaks on first appearance, catching stale caches from kill-during-debounce, day boundary crossing, or timezone changes (Backend Architect), (14) Denormalized `habitIDDenormalized: UUID` on HabitLog recommended for compound index `#Index<HabitLog>([\.date, \.habitIDDenormalized])` — enables fetchLimit=1 on critical tap path without optional-chaining predicate issues (Performance Benchmarker), (15) Device layout breakpoints added: SE/compact (375pt), Standard (390-393pt), Large (414-430pt) with per-class adaptations for card grid, heat map cell size, and spacing (UI Designer), (16) Modal coordination strategy: single `@State var activeSheet: SheetType?` enum per tab with `pendingSheet` queue — prevents SwiftUI `.sheet` stacking issues (UX Architect), (17) fetchOrCreate race condition documented with three-layer defense-in-depth (post-save dedup, DedupService, streak reconciliation) and v1.1 single-writer consolidation plan (Backend Architect), (18) Brand purpose and 4 brand values (Compassionate, Private, Honest, Calm) formalized in Brand Guidelines (Brand Guardian), (19) Lapsed premium win-back card for free users who viewed paywall 2+ times but churned — contextual "Welcome back" card on Today View after 14+ days inactivity (Growth Hacker), (20) GDPR Art. 13(2)(a) retention period disclosed at point of collection in consent UI text, not just privacy policy (Legal).
>
> **Revision Notes (v20):** ~12 consensus fixes from v19 14-agent audit (avg 8.33). **Cross-agent consensus fixes (12 issues, 3+ agents each):** (1) WidgetDataService.writeNow() signature mismatch fixed: changed from pre-computed parameters to accepting `ModelContext` + `Calendar` — queries habits/logs/mood internally, eliminating zero-arg call that wouldn't compile (4 agents), (2) GDPR Art. 7(3) consent withdrawal separated from Art. 17 erasure: withdrawal now stops processing (read-only mode with banner) while preserving data; deletion is a distinct "Delete All My Data" button — EDPB considers forcing deletion on withdrawal a penalty (3 agents), (3) `DailyArcTypography` Swift enum added with all 12 tokens mapping to `Font` values, including display sizes that require `@ScaledMetric` at call site (3 agents), (4) Badge ceremony tiers renamed from gaming terms to arc-aligned: Common→Starter, Rare→Milestone, Epic→Summit, Legendary→Zenith — consistent with brand voice throughout (3 agents), (5) Paywall title updated to "Unlock Your Full Arc" and CTA button to "Unlock Your Arc" — reinforces brand metaphor at conversion-critical moment (3 agents), (6) Stats segment "Overview" renamed to "Your Arc" — the primary data view is the user's arc made tangible (3 agents), (7) Celebration interruption recovery spec added: pending celebrations tracked in @AppStorage, re-presented as static cards on foreground return, confetti not replayed (3 agents), (8) Usability testing protocol expanded: recruitment criteria (5 participants incl. 1 accessibility user), method (moderated remote or Maze), deliverables (severity-ranked findings with video clips) (3 agents), (9) DebouncedSave gains `userCalendar: Calendar` stored property passed to WidgetDataService — prevents timezone bugs in widget data (3 agents), (10) `performSave()` guards against `gdprConsentWithdrawn` flag — consent withdrawal immediately halts data processing at the save layer (3 agents), (11) Insights segment teaser button hardcoded "$5.99" → `{product.displayPrice}` for international compliance (3 agents), (12) Build Step 6 consent withdrawal aligned with Screen spec: includes `gdprConsentWithdrawn` flag, read-only banner copy, and explicit distinction from Art. 17 deletion button (3 agents).
>
> **Revision Notes (v19):** ~25 consensus fixes from v18 14-agent audit (avg 8.26). **Cross-agent consensus fixes (25 issues, 3+ agents each):** (1) StreakEngine full recalculation path: `checkDate` was used before initialization — added `var checkDate = todayCompleted ? today : calendar.date(byAdding: .day, value: -1, to: today)!` at function scope so both incremental and full paths share the same initialized variable (5 agents), (2) `WidgetDataService.writeNow()` fully defined: `static func writeNow(habits: [Habit], streaks: [UUID: Int], moodAverage: Double, weeklyCompletions: [Int]) throws` — accepts pre-computed data from DebouncedSave, encodes to JSON, writes atomically to App Group UserDefaults (4 agents), (3) Duplicate error state sections consolidated: removed "Error states with warmth" block, kept single authoritative "Error states with personality" section with arc-aligned copy (4 agents), (4) Error/loading copy updated with arc metaphor: "We hit a bump in your arc. Pull to refresh." replaces generic "Something went wrong" (4 agents), (5) Widget visual design specs added: dimensions, padding, font sizes, background gradient, dark mode treatment, redacted placeholder for all 3 widget sizes (4 agents), (6) `context.rollback()` replaced with correct SwiftData pattern: import uses a scratch `ModelContext` that is simply discarded on failure — never saved (3 agents), (7) RuleEngine `MoodSnapshot` type defined inline: `struct MoodSnapshot: Sendable { let date: Date; let moodScore: Int; let energyScore: Int }` (3 agents), (8) RuleEngine `calendar` parameter added: `generateSuggestions` now takes `calendar: Calendar` parameter matching CorrelationEngine pattern — removed `Calendar.current` from Task.detached body. Same fix applied to `HealthKitModelActor.createOrUpdateLog` (3 agents), (9) DedupService scope contradiction resolved: canonical scope is "last 30 days using date index" — removed contradictory "fetch all HabitLogs" comment from fetchOrCreate section (3 agents), (10) DedupService + CrashReportingService added to Build Step 8 as explicit numbered items (3 agents), (11) Export DTOs (`HabitDTO`, `HabitLogDTO`, `MoodEntryDTO`) annotated with explicit `: Sendable` conformance (3 agents), (12) Day 4-7+ lapsed user re-engagement: added 5-notification win-back sequence at Days 5/7/10/14/21 of inactivity with arc-themed copy and a 3-notification lifetime cap before going silent (3 agents), (13) Illustration briefs expanded with visual constraints: line weight 2pt, flat fill with brand gradient, max 200pt height / 160pt on compact, aspect ratio 4:3, arc motif required in every illustration as recurring visual element (3 agents), (14) Dark mode experiential direction added: "Dark mode feels like evening journaling by lamplight — warmer, more intimate, slower-paced. When choosing between two valid dark mode options, prefer the one that feels more calm and contemplative." Added to both Design Tokens and Brand Guidelines (3 agents), (15) Consent withdrawal UI added to Build Step 6 as explicit item with full flow: toggle → confirmation dialog → data deletion cascade → reset to first-launch state (3 agents), (16) Timezone strategy documented: all date normalization uses a `userCalendar` captured once per session from `Calendar.current` on @MainActor and passed to all services. Known limitation for timezone travel documented with specific behavior (3 agents), (17) Paywall conversion: added recurring weekly insight teaser card on Today View (after Day 14, dismissable, shows blurred correlation preview) + "Share DailyArc" row in Settings + contextual share prompt after first 7-day streak (3 agents), (18) Onboarding Page 1 progressive disclosure: value props shown first, "Continue" micro-step reveals age/consent section — two mental chunks instead of one wall (3 agents), (19) HealthKit export filtering: `ExportService` explicitly filters `isAutoLogged == true` records from JSON/CSV output unless user grants separate export consent (3 agents), (20) Notification copy contradictions resolved: Settings section marked as "summary only — see NotificationService for authoritative copy" — all variants canonical in NotificationService section only (3 agents), (21) Compound index recommendation strengthened: `#Index<HabitLog>([\.date])` remains primary, added explicit note that `fetchOrCreate` should use `fetchLimit: 1` (not 20) since date+habit post-filter returns at most 1 result (3 agents), (22) Semantic dark mode token hex values added: `backgroundPrimary: #FFFFFF / #000000`, `backgroundSecondary: #F2F2F7 / #1C1C1E`, `textPrimary: #000000 / #FFFFFF`, `textSecondary: #3C3C43(0.6) / #EBEBF5(0.6)` — maps to system colors but now explicitly documented (3 agents), (23) Pipe delimiter input validation: custom activity tag text field strips `|` characters on input, added to Habit Form Step 1 spec (3 agents), (24) Sound table updated: added 4th row "Streak loss settle" with trigger, duration (~0.3s), and character — resolves inconsistency between 3-sound table and 4-sound personality descriptions (3 agents), (25) `applyRecovery` calendar parameter: function signature updated to `applyRecovery(for:dates:context:calendar:)` matching all other StreakEngine methods — passes calendar through to `recalculateStreaks` (3 agents).
>
> **Revision Notes (v18):** ~40 fixes from v17 14-agent audit (avg 8.25). **Cross-agent consensus fixes (10 issues, 3+ agents each):** (1) Build Step 4 heat map colors replaced GitHub green hex values with canonical Sky-to-Indigo brand gradient from Screen 5 (5 agents), (2) Bonferroni `testedCount` changed from `habits.count` to actual count of habits that passed class imbalance guard and produced a non-nil correlation — fixes over-conservative correction (4 agents), (3) English keyword field fixed from 101→93 chars: removed "healthy" (stem overlap with "health") — was silently truncating in App Store Connect (3 agents), (4) Arc metaphor threaded into daily-use copy: streak milestone messages, notifications, empty states, error states all now use arc language (4 agents), (5) `recalculateStreaks` and `computeBestStreak` now take `calendar: Calendar` parameter matching CorrelationEngine pattern — prevents timezone bugs if called from non-main-actor context (3 agents), (6) Weekly summary notification added to NotificationService: fires Sunday evening with deep link to Stats tab (3 agents), (7) Heat map colorblind accessibility: pattern overlays added for `isDifferentiateWithoutColorEnabled` (3 agents), (8) Consent withdrawal UI added: "Withdraw Processing Consent" toggle in PrivacySettingsView per GDPR Art. 7(3) (3 agents), (9) Celebration message variants rewritten with arc metaphor per milestone tier (3 agents), (10) `WidgetConfigurationIntent` struct defined with `WidgetConfigurationIntent` protocol conformance (3 agents). **Additional fixes from individual agents:** (11) `CorrelationResult` gets explicit `: Sendable` conformance annotation for consistency, (12) RuleEngine rules 10/11 add explicit `energyScore == 0` filter note, (13) `minimumPairedDays = 14` named constant for Pearson threshold, (14) Independent variance check (`sumX2 > 1e-6 && sumY2 > 1e-6`) replaces product-only epsilon guard in Pearson, (15) `StreakEngine` annotated `@MainActor` explicitly, (16) `HKHealthStore.requestAuthorization(toShare: nil, ...)` — nil is semantically correct for read-only, (17) `Color(light:dark:)` implementation updated to use `UIColor { traits in }` dynamic provider (deprecated `UITraitCollection.current` removed), (18) Import rollback: explicit `context.rollback()` call on failure, (19) `WidgetDataService.writeNow()` wrapped in do/catch — widget write failures no longer affect save success path, (20) Data migration playbook added: v1.0 models frozen, all changes go to DailyArcSchemaV2, (21) `MoodEntry` gets explicit `#Index<MoodEntry>([\.date])` declaration, (22) `@preconcurrency import HealthKit` added for Swift 6 strict concurrency, (23) DedupService algorithm specified: Dictionary grouping by (habit.id, date), batch size 500, O(n), (24) Parental consent mechanism enhanced with email verification note, (25) CCPA "Do Not Sell or Share" link added to Settings, (26) Localized privacy policy requirement added to pre-launch checklist, (27) GDPR Art. 30 records of processing activities requirement added, (28) Breach notification alternative via hosted JSON added, (29) Mental health disclaimer added to first mood check-in, (30) COPPA turning-13 behavior explicitly defined, (31) Streak loss compassion copy section formalized with graduated messaging by streak length, (32) Notification copy variants added (3-5 per type with arc metaphor), (33) Error message copy specified per failure mode, (34) Paywall copy leads with emotional value proposition, (35) iPhone SE layout adaptation section added, (36) Onboarding Page 2 premium expectation-setting line added, (37) Day 14 insight awareness nudge on Today View, (38) Dark mode brand expression paragraph added to Brand Guidelines, (39) Sound design emotional personality descriptions added, (40) Per-context illustration briefs for empty states.
>
> **Revision Notes (v17):** ~40 fixes from v16 14-agent audit (avg 7.18). **Critical compile fixes (6-agent consensus, 2 fixes):** (1) `applyRecovery` now passes required `isFirstCallToday: false` and `isDeletion: false` to `recalculateStreaks` (was missing — would not compile), (2) TodayView usage example now passes `isFirstCallToday: !streakUpdatedToday.contains(habit.id)` to `recalculateStreaks`. **ASO critical (3 fixes):** (3) English title shortened to 30 chars: `DailyArc: Habit & Mood` (was 31 — would be rejected), (4) German keywords trimmed from 117→98 chars (removed Laune/Achtsamkeit dupes), (5) French keywords trimmed from 101→97 chars (removed bienveillance, added rappel). **Code correctness (5 fixes):** (6) `computeCorrelations` `calendar` parameter is now REQUIRED (no default) — prevents silent timezone bugs in Task.detached, (7) Bonferroni denominator changed from `raw.count` (post-filter) to `testedCount` tracking all habits entering compactMap (pre-filter) for correct familywise error control, (8) `stableHash` utility and FeatureFlag bucketing code unified to both use `UInt` (was UInt32 in feature flag comment — produced different values on 64-bit), (9) Incremental O(1) streak path now finds "most recent applicable day" instead of hardcoded yesterday — fixes silent fallthrough for non-daily habits, (10) `ModelContainer` failure recovery now offers user choice (repair vs reset) instead of silently deleting data. **Legal/compliance (5 fixes):** (11) Data breach notification procedure added (GDPR Art 33/34 — was entirely missing), (12) APPI compliance section added for Japan Phase 1 market (purpose notification, cross-border TelemetryDeck disclosure, APPI-specific rights), (13) Data controller identity + retention criteria added to onboarding consent screen (GDPR Art 13(1)(a)/(2)(a)), (14) GDPR Art 21 right to object added to privacy policy, (15) `stableUserID` Keychain generation deferred to first analytics consent or feature flag activation (TTDSG Section 25 compliance for German market). **Brand/UX (7 fixes):** (16) Heat map color scale changed from GitHub green to brand Sky-to-Indigo gradient, (17) Today View habit count badge uses arc language ("3/5 on today's arc"), (18) Notification copy unified with arc language in all bodies, (19) "Energy Arc" picker label reverted to "Energy" (arc metaphor reserved for trajectories, not point-in-time measurements), (20) Celebration variant "Most people don't make it to 10" replaced with "100 days of choosing yourself" (was subtly condescending), (21) Paywall "Not now" dismissal adds warm acknowledgment ("No worries — DailyArc is great free too"), (22) Day 3 paywall delayed to NEXT SESSION after any celebration (was 5-second same-session delay). **Spec consistency (5 fixes):** (23) Onboarding Page 2 "1-4" in build step → "1-3" matching screen spec and free tier limit, (24) Sound duration reconciled: milestone chime 0.5s everywhere (was 0.4s in personality section), (25) Onboarding A/B test template count "1-4" → "1-3" matching screen spec, (26) `HKHealthStore.requestAuthorization(toShare: Set<HKSampleType>())` — explicit Set type (was `[]` which infers Array), (27) `ModelContainer(for:)` initializer corrected to use `Schema(versionedSchema:)` pattern. **Performance (3 fixes):** (28) RuleEngine `generateSuggestions` refactored to use `Dictionary(grouping:)` pattern matching CorrelationEngine (was O(H*L) filter, now O(L+H)), (29) Compound index added: `#Index<HabitLog>([\.date])` note expanded to recommend app-level Dictionary grouping by habit ID for queries filtering by habit (SwiftData #Index limitation with relationships), (30) Keychain reads deferred to after first frame render (was synchronous on launch critical path). **Growth/Retention (4 fixes):** (31) Day 15 "halfway to 30" acknowledgment card added to bridge Day 14-30 motivation gap, (32) Day 21 "3-week arc" toast added, (33) "Comeback Arc" celebration variant for users who rebuild a streak they previously lost at 30+ days, (34) Activation metric updated to require at least 1 mood log in first 7 days (was habit-only). **Whimsy (3 fixes):** (35) v1.1 Easter eggs (100th open, seasonal tints, Friday 13th) pulled into v1.0 for denser surprise, (36) Streak loss gets soft "settle" sound (brief descending half-step tone, <0.3s), (37) Volume badges assigned to ceremony tiers (Inner Arc=Common, Century Arc=Rare, Mindful Arc=Rare, Insight Arc=Epic).
>
> **Revision Notes (v16):** ~31 fixes from v15 14-agent audit (avg 7.29). **Critical code fixes (4+ agent consensus, 4 fixes):** (1) CorrelationResult struct: added `var isSignificant: Bool` field (was missing — code wouldn't compile), (2) computeCorrelations code flow: `compactMap` now assigns to `raw`, Bonferroni correction block operates on `raw` and returns sorted `results` (was unreachable dead code), Bonferroni denominator uses `raw.count` (tested habits) not `habits.count` (all input), (3) `isSignificant` function: replaced fixed alpha=0.05 lookup table with Abramowitz & Stegun + Cornish-Fisher analytical approximation that correctly uses the `alpha` parameter (Bonferroni was a no-op before), (4) StreakEngine: added `isFirstCallToday: Bool` required parameter (no default) enforcing double-increment guard at type level, not comments. **Legal/compliance (3 fixes):** (5) COPPA `isCOPPABlocked` now stored in Keychain (not just AppStorage) — survives reinstall, prevents child bypass, (6) GDPR Art 8 locale-aware age gate for Phase 1 EU markets (DE=16, FR=15, ES=14) with parental consent screen, (7) DPIA expanded from checkbox to full Art 35(7) outline (systematic description, necessity, risks, measures). **ASO (4 fixes):** (8) German keywords: removed Streaks/Tagesablauf dupes, added Wohlbefinden (now 100 chars, was 121 — would have been rejected), (9) English keywords: removed "wellness"/"streak" subtitle dupes, added "journal"/"checklist" (99 chars), (10) Japanese keywords: expanded from 47→95 chars (added 7 compound terms: 習慣化, 体調管理, 気分日記, メンタルヘルス, ライフログ, 自己改善, 健康管理), (11) English title count corrected 29→30. **Arc metaphor consistency (8 fixes):** (12) "Full Circle" badge → "Complete Arc" (naming convention), (13) Day 5 nudge references "Rising Arc badge" not generic "streak badge", (14) Day 10 toast uses arc language, (15) Onboarding Page 3 title → "Your arc starts here", (16) "Start Tracking" → "Start Your Arc", (17) Archive toast uses arc language, (18) Weekly summary: 8 variants (up from 4) with arc language + compassionate negative-delta handling, (19) Share card footer includes secondary tagline per hierarchy. **Content/UX (7 fixes):** (20) Stats empty state: specific day count replaces vague "a few days", (21) Streak loss singular grammar fix ("1 day" not "1 days"), (22) Onboarding value props: removed overlapping bullet, added privacy pillar, (23) Recurring notification body copy added (evening reminder, streak check-in, mood reminder — were trigger-only, no copy), (24) Share cards extended to 60/500/1000 milestones (were 7/30/100/365 only), (25) "Insight Arc" badge added to volume badges + referenced in Day 14 ceremony (was "Data Scientist" with no table entry), (26) Mood consent re-prompt: explicit `moodConsentPromptDismissed` flag prevents EDPB consent-nagging. **Architecture (4 fixes):** (27) computeCorrelations takes `calendar` parameter (captured on @MainActor before Task.detached), (28) Correlation cache: added 24h TTL safety net, (29) Recovery dates: added 30-day pruning on every read, (30) DebouncedSave `performSave()` code now includes `WidgetDataService.writeNow()` call. **Spec consistency (2 fixes):** (31) Delete All My Data: fixed `recoveryDates_*` → `allRecoveryDates` matching StreakEngine + added Keychain cleanup, (32) Onboarding Page 1 consent: reconciled single checkbox with authoritative 3-toggle GDPR flow. **Brand (1 fix):** (33) Dark mode brand intent articulated ("intimate evening reflection") with specific visual treatments.
>
> **Revision Notes (v15):** ~18 fixes from v14 14-agent audit (avg 7.50). **Cross-agent consensus fixes (12 issues, 3+ agents each):** (1) Spanish subtitle shortened from 32→26 chars ("Rachas, stats y bienestar") to fit 30-char limit, (2) ALL localized keyword fields de-duplicated — removed words that overlap with title/subtitle stems (DE: -2, JP: -3, FR: -3, ES: -4), replaced with unique high-value terms, added ZERO-duplication rule, (3) Step 7a haptic contradictions fixed to match authoritative Haptic Feedback Map (habit: `.light` not `.medium`, streak loss: `.light` not `.warning`), (4) StreakEngine incremental O(1) double-increment bug fixed — added `yesterdayCompleted` guard + caller-side `streakUpdatedToday` Set to prevent re-increment on same day, (5) Naive Pearson formula removed from Screen 5 — now references canonical two-pass mean-centered implementation in CorrelationEngine (eliminates dual-implementation confusion), (6) COPPA under-13 Keychain DOB deletion: both Keychain AND AppStorage wiped on block, stores only `isCOPPABlocked` boolean (no age data retained per COPPA 312.3(c)), (7) Art 9 mood consent toggle added to onboarding consent flow (default OFF, with explanation text + re-prompt on first Stats visit if not yet enabled), (8) Bonferroni correction integrated into `computeCorrelations` — corrected alpha passed to `isSignificant`, denominator uses total habits tested (not filtered count), `isSignificant` field added to CorrelationResult, (9) Correlation result caching added — StatsViewModel caches `[CorrelationResult]`, invalidates on new log/mood/date change, prevents O(H*M) recomputation on tab switches, (10) Volume badges renamed to arc convention (Inner Arc, Spectrum Arc, Century Arc, Mindful Arc), (11) Confetti contradiction resolved — milestone table now says "NO confetti" for 7/14 days matching escalation section (confetti starts at Day 30), (12) Onboarding Page 1 tagline fixed to secondary ("Every day adds to your arc.") per tagline hierarchy. **Brand/Content (4):** (13) Share card layout adds secondary tagline "Every day adds to your arc." below badge, (14) Screenshot text overlays aligned with Screenshot Strategy headlines (were divergent), (15) Empty state "Your story" → "Your arc is just beginning" (brand consistency), (16) German subtitle "Serien" → "Streaks" (avoids "TV series" confusion). **ASO (2):** (17) Localized App Store description opening paragraphs added for DE/JP/FR/ES (conversion-critical first 3 lines), (18) App Store description CTA added ("Download DailyArc free today. Your arc starts now.").
>
> **Revision Notes (v14):** ~35 fixes from v13 14-agent audit (avg 7.86). **Top 10 cross-agent consensus fixes:** (1) Step 5b correlation card color fixed to gray/textSecondary matching canonical definition (6+ agents), (2) German/Spanish localized titles shortened to fit 30-char App Store limit (ASO critical), (3) COPPA DOB storage: ALL `@AppStorage("dobMonth"/"dobYear")` → Keychain via `KeychainDOBService` + launch-time Keychain check (survives reinstall), (4) CorrelationEngine: added `startDate` filter (prevents artificial skip-day inflation), `Task.isCancelled` checks between habit iterations, class imbalance guard extended to ALL habits (not just binary — min 3 per class), (5) StreakEngine incremental O(1) currentStreak on normal completion (only full O(d) recompute on deletion/undo), (6) DebouncedSave Swift 6 fix: `Task { @MainActor [weak self] in` for both trigger() and retryTask, (7) Statistical significance v1.0: t-statistic with lookup table + Bonferroni correction for multiple comparisons, (8) Paywall trigger count corrected "4 contexts" → "5 contexts", (9) Free user insight share contradiction resolved (one share card after Day 14), (10) Art 9 mood consent default OFF (EDPB requires affirmative action). **Architecture/Code (8):** (11) Pearson two-pass mean-centered algorithm for numerical stability (eliminates catastrophic cancellation), (12) WidgetDataService debounce contradiction resolved — no independent timer, writes synchronously from DebouncedSave success path, (13) HealthKitModelActor lifecycle specified (created once in App.init, stored as @State, shared ModelContainer), (14) MoodEntry dedup coverage added (fetchOrCreate + DedupService by latest createdAt), (15) `Color(light:dark:)` implementation specified in Build Step 1 (UITraitCollection resolution), (16) stableUserID generation added to Build Step 1 instructions (Keychain, for flags + attribution + referral), (17) FeatureFlag bucketing rebalanced 33/33/34 (equal thirds for statistical power), (18) computeBestStreak stale comment fixed. **UI/Brand (8):** (19) Badge names use arc language (First Arc, Rising Arc, Blazing Arc, Golden Arc, Complete Arc, etc.), (20) Energy picker header "Energy Arc" reinforces arc metaphor in daily interaction, (21) `premiumGold` light mode darkened #FFD700 → #B8860B (DarkGoldenrod) for WCAG AA on white, (22) `cardShadow` made adaptive (0.08 light / 0.24 dark) for dark mode depth, (23) Corner radius tokens added to DailyArcTokens (small/medium/large/capsule), (24) 365-day arc animation visual payoff fully specified (1.5s draw, gold line, pulse, hold), (25) Day 3 celebration/paywall collision avoidance (5s delay after badge ceremony), (26) Share card privacy keyword list canonicalized (single source of truth, no divergent lists). **Growth/ASO (5):** (27) Weekly recap share card design spec added (layout, dimensions, privacy, campaign tag), (28) Localized keyword fields for DE/JP/FR/ES (100 chars each), (29) Localized promotional text for all Phase 1 markets, (30) Screenshot text overlays translated for all 5 markets, (31) Notification-denied users get in-app re-engagement fallbacks (welcome-back card, in-app Day 5/10 overlays). **UX/Legal (3):** (32) Usability testing plan added to pre-launch checklist (5 participants, 5 tasks, success criteria), (33) Haptic map streak loss `.warning` → `.light` (matches compassion section), (34) Free user insight share wording clarified.
>
> **Revision Notes (v13):** ~45 fixes from v12 14-agent audit (avg 8.04). **Consensus fixes (12, 3+ agents each):** (1) RuleEngine refactored from `@MainActor class` to caseless `enum` with static methods + Sendable snapshots (matches CorrelationEngine pattern, eliminates Task.detached contradiction), (2) StreakEngine `computeBestStreak` optimized: incremental O(1) on completion, full O(n log n) recompute only on deletion/undo (new `isDeletion` parameter), (3) `shouldAppear` duplicate in CorrelationEngine REMOVED — now delegates to `DateHelpers.shouldAppear` (single source of truth), (4) fetchOrCreate race: post-save dedup check added in HealthKitModelActor (query for duplicates after save, merge by keeping highest count), (5) Arc metaphor expanded: heat map section header "Your Arc This Year" + curved baseline, celebration arc-drawing animation before confetti, streak loss copy uses "arc" language, badge descriptions reference arc, (6) Correlation card color canonical definition clarified (gray for neutral, not orange — all build step references must match), (7) Widget JSON migration handler specified: `ignoreUnknownKeys`, safe defaults for missing fields, `os_log` for version mismatches, backward-compatible additive schema, (8) App Store description opener rewritten benefit-first (leads with action verbs, not question), (9) Share privacy keyword list localized for Phase 1 locales (German, Japanese, French, Spanish — top 10 per locale), (10) `habit.id.hashValue` in celebration variants replaced with `stableHash` (djb2/SHA256) — same fix already applied to feature flags, (11) Feedback state colors made adaptive as PRIMARY definition (not comments): `Color(light:dark:)` for success/warning/error/info, `streakFire` explicit hex, `premiumGold` adaptive, (12) Localized App Store titles actually translated (German/Japanese/French/Spanish subtitles were English in v12). **Code/Architecture (8):** (13) CorrelationEngine cancellation: stored Task handle + `Task.isCancelled` checks between iterations, (14) NotificationCenter task leak fixed: stored `healthKitObserverTask` handle + `.onDisappear` cancel, (15) MoodEntry.energyScore sentinel 0 explicitly defined (distinct from score 1, filtered from analysis), (16) DedupService algorithm specified: single-query scan, in-memory grouping, 200ms budget with bail-and-defer, (17) Export DTO structs require explicit `Sendable` conformance, (18) RuleEngine guard changed from `monthLogs.count >= 7` to `applicableDays >= 7`, (19) Navigation architecture section added (tab navigation, modal/push patterns, deep links), (20) Date navigation long-press calendar picker for backfill. **Legal/Privacy (4):** (21) DPIA requirement added to pre-launch checklist (GDPR Art. 35 for health data), (22) COPPA age gate reinstall protection via Keychain storage, (23) GDPR Art. 9 mood-correlation explicit consent toggle (separate from core consent, withdrawable), (24) Statistical significance v1.1 plan (p-value via t-statistic). **UI/UX/Brand (8):** (25) Dark mode as brand expression (true black OLED, elevated cards, arc glow effect, "evening edition"), (26) Sound design personality specified (pop/chime/fanfare — each distinctly recognizable), (27) Badge ceremony tiered by rarity (common=toast, rare=modal, epic=confetti, legendary=custom particles), (28) VoiceOver undo toast: pause auto-dismiss on focus, extend to 6s, add explicit dismiss button, (29) Day 3-14 motivation valley mitigated (Day 3/5/7/10/14 touchpoints), (30) Third Easter egg added (palindrome streak), (31) Onboarding Page 1 overload addressed (value props staggered, scroll enabled), (32) Widget timeline refresh throttled (60s minimum between reloads). **Growth (5):** (33) Paywall trigger #5: onboarding Page 3 high-intent moment ("Unlock the full arc" preview), (34) Share card triggers expanded (persistent share in PerHabitDetailView, weekly recap share), (35) v1.0 referral data collection via Keychain stableUserID in share URLs, (36) Referral data prep for v1.1 badge system, (37) Friday the 13th Easter egg planned for v1.1.
>
> **Revision Notes (v12):** ~40 fixes from v11 14-agent audit. **Consensus fixes (5+ agents):** (1) GDPR legal basis inconsistency resolved — privacy policy now uses Consent for core data and analytics, matching in-app table, (2) `String.hashValue` non-deterministic bucketing replaced with stable SHA256-based hash, (3) `shouldAppear` extraction to DateHelpers.swift mandated in Build Step 1, (4) fetchOrCreate race condition mitigations strengthened (HealthKit 500ms delay + re-verify), (5) Onboarding Page 1 layout guidance added (scroll, spacing, SE adaptation), (6) Share card privacy guard expanded (30+ keywords, per-habit private toggle, localization note), (7) MetricKit PerformanceMonitoringService fully specified, (8) Illustration style guide added to Brand Guidelines, (9) Dark mode semantic color tokens made adaptive via Color(light:dark:) pattern, (10) Notification budget worst-case validated + per-habit cap, (11) `displayLarge` fixed to use `@ScaledMetric` for Dynamic Type, (12) Analytics opt-in blind spot acknowledged with MetricKit fallback. **Code/Architecture (10):** (13) `@MainActor` added to TodayViewModel/StatsViewModel, (14) Pearson epsilon raised to 1e-6, (15) Binary habit class imbalance guard (min 3 per class), (16) `modelContext.autosaveEnabled = false` documented, (17) RuleEngine offloaded to Task.detached matching CorrelationEngine pattern, (18) DebouncedSave ownership moved to App struct, (19) NotificationCenter Swift 6 pattern updated to async for-await, (20) Widget JSON version mismatch fallback specified, (21) Post-import reconciliation phase added, (22) Export cancellation + progress reporting via AsyncStream. **Legal (8):** (23) CCPA "Do Not Sell" button added to Settings, (24) Mood data GDPR Art. 9 health data analysis documented, (25) COPPA block screen emoji removed, (26) Mental health disclaimer added at insight delivery point, (27) GDPR Art. 13(2)(f) profiling disclosure added, (28) Consent text version hash stored, (29) HealthKit consent withdrawal triggers data deletion, (30) DPA moved to Step 1 blocking prerequisite. **UI/UX/Brand (10):** (31) Illustration style guide with arc motif, (32) Activity tag chip visual spec completed, (33) Streak recovery banner visual spec, (34) Badge locked state precise spec, (35) Correlation card colors linked to semantic tokens, (36) Date navigation animation specified, (37) Tagline hierarchy clarified, (38) Spacing token Swift code added, (39) Heat map accessibility improved (weekly grouping, rotor actions), (40) Celebration escalation for late-game milestones. **Growth/Content (5):** (41) App Store description opener rewritten benefit-first, (42) Share card copy tiered by milestone, (43) Keyword field filled to 100 chars, (44) Day-0 activation micro-metric added, (45) Push notification soft-ask pattern specified.
>
> **Revision Notes (v11):** 17 fixes from v10 audit. **Copy/UX (5):** (1) App Store description lede rewritten with emotional hook (not tagline repeat), (2) COPPA block screen copy specified, (3) onboarding value props rewritten benefit-first, (4) paywall price anchor improved with per-day math + competitor comparison, (5) multiple comparisons disclaimer for correlation display. **Code/Architecture (6):** (6) NotificationCenter dispatch-to-MainActor critical note, (7) Widget AppIntent stub added to project structure, (8) Export DTO conversion boundary documented (@Model→DTO on MainActor), (9) HabitFrequency enum schema contract comment, (10) streak recovery transaction safety doc comment, (11) DedupService timeout/budget behavior specified. **Performance (1):** (12) scroll performance targets added (hitch rate, hang diagnostics, 60fps on A12). **Analytics/Science (3):** (13) correlation rolling window v1.1 enhancement documented, (14) mood scale methodology acknowledgment (ordinal-as-interval, acquiescence bias), (15) persona research caveat with validation plan. **Infrastructure (2):** (16) feature flag deterministic hash-based bucketing mechanism, (17) version header updated to v11.
>
> **Revision Notes (v10):** ~45 fixes from v9 audit targeting 10/10. **Code (6):** (1) Pearson clamping for floating-point edge cases, (2) memory pressure handler purges cached data, (3) DebouncedSave flushes on .inactive (earlier than .background), (4) App Group UserDefaults cleanup in Delete All Data, (5) ModelContainer failure recovery with user-facing error, (6) DedupService in project structure + build step. **Content/Brand (6):** (7) celebration variants for 60/90/180/500/1000 days, (8) streak loss encouragement variants (3), (9) keywords trimmed to 93 chars, (10) brand positioning statement + voice matrix, (11) bug fix release notes template, (12) arc metaphor reinforced in onboarding. **UI/Design (6):** (13) pressed/active + focus state tokens, (14) feedback state dark mode hex values, (15) tab bar badges spec, (16) confetti particle detailed spec, (17) celebration priority queue, (18) share card visual dimensions + layout. **Legal/Growth (8):** (19) GDPR Article 77 complaint right, (20) legal basis per processing activity table, (21) notification daily budget (max 3/day), (22) activation recovery push (48h + 7d), (23) TelemetryDeck DPA in launch checklist, (24) conversion funnel adds "Activated" stage, (25) EU Consumer Rights Directive liability carve-out, (26) review solicitation multi-trigger (7d/14d/100d). **Typography (2):** (27) caption2 + callout intermediate sizes, (28) insight share for free users clarified.
>
> **Revision Notes (v9):** Targeting 10/10 across all 14 agents (v8 average: 9.21). **Unanimous fix (14/14 agents):** moodEmoji computed property now returns "" for sentinel value 0 (was returning "😐", corrupting display + correlation data). **Code fixes (7):** (1) moodEmoji sentinel, (2) all "6 habits" refs→3 in build steps 3/5a/7a, (3) StreakEngine singleton via @State (no more per-tap instantiation), (4) Pearson correlation filters moodScore==0 from computation, (5) architecture decisions renumbered 28-34 sequentially, (6) Habit Form cancel/back navigation specified, (7) HealthKit denial handling with toggle revert. **Growth/ASO overhaul (12):** (8) keyword field optimized (removed "tracker" dupe, added "diary/planner/improvement/mental/healthy"), (9) subtitle "Daily Journal"→"Wellness Log" (eliminates "daily" dupe from DailyArc), (10) German/French subtitles within 30-char limits, (11) full 4000-char App Store description written, (12) activation metric defined (3-of-7-days), (13) K-factor target (≥0.05) + measurement plan, (14) conversion target raised to 5-7% (alert at <4%), (15) pricing A/B test added as 4th experiment, (16) "What's New" release notes template, (17) promotional text strategy, (18) insight share card variant for Day 14+ users, (19) Day 0 value demo on onboarding Page 3. **UI/UX/Whimsy (14):** (20) badge unlock ceremony specified, (21) celebration message variants (2-3 per tier), (22) first-ever mood log celebration, (23) authoritative 17-row haptic map, (24) skeleton loading spec, (25) toast/snackbar component spec, (26) CompletionCircle spec, (27) heat map cell dimensions (12pt/3pt gap), (28) opacity + border width tokens, (29) SF Symbol/iconography guidelines, (30) energy picker→tappable circles, (31) archive compassion toast, (32) post-365 milestones (500/1000 days), (33) BadgesView navigation + file. **Technical/Legal/Performance (15):** (34) cold launch <1.0s target + deferred init, (35) CPU profiling targets, (36) HealthKit 10s query timeout, (37) DebouncedSave lifecycle safety note, (38) HealthKit→streak NotificationCenter bridge, (39) privacy policy data controller identity, (40) GDPR consent record enriched (version+scope), (41) CCPA explicit "Do Not Sell" disclosure, (42) HealthKit re-consent dialog in Settings (GDPR Article 9), (43) mental health disclaimer strengthened, (44) explicit data retention statement, (45) ToS limitation of liability capped, (46) Apple LAEULA reference, (47) widget write chain clarified (after DebouncedSave), (48) Badge Collection nav + BadgesView.swift added.
>
> **Revision Notes (v8):** Comprehensive fixes targeting 10/10 across all 14 agents. **Tier 1 critical code fixes (5):** (1) FeatureFlag @AppStorage in computed property → UserDefaults.standard (won't compile fix, 4-agent consensus), (2) MoodEntry.fetchOrCreate default moodScore 3 → 0 sentinel (prevents central tendency bias, 5-agent consensus), (3) "Pick 2-4" ghost fix → "Pick 1-4" (5-agent consensus), (4) age gate storage reconciled to dobMonth+dobYear across all 3 locations, (5) tech debt #6 updated fetchLimit=1→20 to match implementation. **Tier 2 architecture fixes (7):** (6) @MainActor on StreakEngine + RuleEngine (Swift 6 safety), (7) DebouncedSave: removed @Observable (view invalidation overhead), separated retryTask from pendingTask (orphan bug), added onError callback, (8) cross-context HabitLog race condition documented with 3 mitigations + periodic dedup job, (9) UIDevice.current.isMuted removed (doesn't exist) — .ambient category respects silent mode, (10) tag chip 36pt→44pt + color swatch 40pt→44pt (Apple HIG minimum), (11) analytics default OFF for GDPR Article 6 + onboarding opt-in prompt, (12) notification permission prompt added to onboarding analytics toggle. **Tier 3 growth/strategy overhaul (11):** (13) free tier reduced 6→3 habits (conversion optimization), (14) 4 paywall trigger contexts (hard limit, feature gate, Day 3 engagement, 7-day milestone) + price anchoring copy, (15) user personas added (3 archetypes with conversion triggers), (16) "Winding down" → "Good evening" (warmer), (17) "needs attention" → "is at X% — small steps count!" (on-brand), (18) premiumGold dark mode hex added, (19) disabled + disabledText state tokens added, (20) screenshot benefit headlines added (benefit-first marketing), (21) weekly summary default ON (retention touchpoint), (22) localized subtitles within 30-char limits, (23) Week 3 overload split → 9-11 week timeline.
>
> **Revision Notes (v7):** Targeted fixes from sixth 14-agent review (8.4→target 9.0+). First round where ALL 14 agents trended upward. **Tier 1 (4 must-fix):** (1) App Store title fixed to 29 chars using colon ("DailyArc: Habit & Mood Tracker"), (2) HabitLog.fetchOrCreate gets fetchLimit=20, (3) paywall "Export your data (JSON/CSV)" → "CSV export & data import" (3-agent consensus fix), (4) CorrelationEngine → enum with static methods (implicitly Sendable for Task.detached), HealthKitService → actor (Swift 6 safe). **Tier 2 (4 high-priority):** (5) StreakEngine.recalculateStreaks takes pre-fetched [HabitLog] parameter (eliminates habit.logs relationship fault on every tap), (6) DebouncedSave error recovery: retry once + surface lastError to UI as non-blocking alert (silent data loss was worst UX), (7) onboarding "Pick 2-4" → "Pick 1-4" matching actual validation, (8) ImageRenderer deferred to Share button tap (lazy, not eager at celebration — eliminates main-thread contention). **Tier 3 + medium (14 fixes):** (9) feature flag enum ships in v1.0 (all control, plumbing for v1.0.1 A/B tests), (10) streak warning → morning-after "Yesterday was a full day" at 9 AM (respects sleep, eliminates midnight anxiety), (11) streak recovery capped at 2 per 30-day window per habit, (12) analytics consent toggle in Settings, (13) Terms of Service / EULA section added, (14) DebouncedSave guarded against re-creation on repeated .onAppear, (15) heat map colors dark-mode adapted (6 adaptive colors), (16) mood emoji picker explicitly no-default (prevents central tendency bias), (17) 365-day background Task cancellable via .onDisappear, (18) loading/error states with personality copy, (19) onboarding delight moments (staggered animations, haptics, confetti preview on Page 3), (20) 14-day insight lockout shows progress bar toward unlock, (21) Pearson vs Spearman justification + selection bias caveat documented, (22) 2 Easter eggs ship in v1.0 (New Year's, app anniversary), age gate stores month+year explicitly.
>
> **Revision Notes (v6):** Targeted fixes from fifth 14-agent review (7.9→target 9.0+). **Tier 1 (4 must-fix):** (1) HealthKitService Sendable — backfillHabitLogs/registerObserver take habitID:UUID+typeRaw:String (not @Model Habit), (2) DebouncedSave full 40-line implementation with trigger()/flush() + usage pattern in TodayView, (3) extractSnapshots takes pre-fetched allLogs parameter and groups by habit ID in one pass (eliminates N+1 relationship faults), (4) ModelContainer merge policy documented (last-writer-wins acceptable for idempotent HealthKit writes). **Tier 2 (4 high-priority):** (5) Paywall copy — removed JSON export from premium features list, clarified "CSV export & data import", (6) GDPR consent withdrawal (Article 7(3)) + data retention policy added, (7) keyboard dismissal (.scrollDismissesKeyboard + toolbar Done button), (8) correlation confidence qualifiers (n<14 suppressed, 14-30 "limited data", 30-60 "early pattern") + point-biserial equivalence note. **Tier 3 + strategic gaps:** (9) colorHex→colorIndex palette-based color system for reliable dark mode (single Int index maps to both light and dark hex), (10) widget deep links (dailyarc:// URL scheme → tab navigation), (11) journaling prompt "Rate 1-10" fixed to match 1-5 mood scale, (12) Week 6 timeline rebalanced (7a alone, 7b+8a in Week 7, 8b+polish in Week 8), (13) ASO title optimized (30 chars, no keyword duplication across title/subtitle/keywords), (14) TestFlight go/no-go criteria with 10-point checklist + App Store rejection contingency, (15) growth experiment framework (3 A/B tests for v1.1), (16) non-streak achievements (volume-based badges), (17) Easter eggs + seasonal theming planned for v1.1, (18) brand guidelines section added, (19) Step 5a/5b overlap eliminated (correlation UI consolidated in 5b), (20) ImageRenderer documented as @MainActor-required, (21) Step 8 backfillHabitLogs signature synced with Sendable fix, (22) referral incentive mechanism designed for v1.1.
>
> **Revision Notes (v5):** Targeted fixes from fourth 14-agent review (7.4→target 8.5+). **1 critical fixed:** CorrelationEngine Sendable violation — @Model objects cannot cross actor boundaries; extracted Sendable HabitSnapshot/MoodSnapshot/LogSnapshot DTOs, compute runs on plain structs via Task.detached, CorrelationResult stores habitID/habitName (not Habit reference). **11 high-severity fixes:** (1) Heat map "tooltip popover" → "fixed detail bar" contradiction resolved in all locations, (2) HealthKitModelActor direct save() documented as intentional exception (actor-isolated context), (3) StatsView @Query replaced with ModelContext.fetch for progressive loading (30 days on appear → 365 in background), (4) requestAuthorization return type Void not Bool, (5) fear-based notification copy rewritten to warm encouraging tone ("You've got this" not "Don't break your streak!"), (6) ATT explicitly not required (TelemetryDeck uses no IDFA/cross-app tracking), (7) privacy policy template added as spec appendix with all required sections, (8) Design Tokens section added: semantic UI colors, typography scale, spacing system (4pt base), component specs with corner radii/touch targets, animation curves/durations for all interactions, (9) sound design specified (3 sounds: pop/chime/fanfare), (10) pre-onboarding gates collapsed — age+consent embedded in onboarding page 1 (5 screens → 3 = 15-30% drop-off recovery), (11) localization strategy added (Phase 1: App Store metadata for 5 markets, Phase 2: in-app strings in v1.1). **Strategic additions:** post-launch monitoring plan with Week 1 dashboard/alert thresholds/review response plan, North Star metric (Weekly Active Loggers) + conversion funnel stages, first-ever habit completion celebration, weekly summary notification, badge collection screen, String(localized:) wrappers from day 1 for extraction-ready localization.
>
> **Revision Notes (v4):** Targeted fixes from third 14-agent review. All v2→v3 fixes confirmed correct (13/13 blockers resolved). **1 showstopper fixed:** isRecovered logs now correctly COUNT toward streak calculations (only excluded from correlation/rule analysis) — without this, paying for streak recovery had no effect. **8 critical/high issues fixed:** (1) @Model classes nested inside VersionedSchema enum with module-scope typealias, (2) HKCategoryQuery replaced with HKSampleQuery (HKCategoryQuery doesn't exist), (3) Mindful minutes corrected from HKQuantityType to HKCategoryType(.mindfulSession), (4) Minimum iOS bumped to 17.4 for #Index macro compatibility, (5) persistentModelID predicates replaced with UUID-based post-fetch filtering (#Predicate has limited persistentModelID support), (6) StreakEngine no longer calls context.save() directly — defers to DebouncedSave, (7) CorrelationEngine uses Task.detached (not Task which inherits @MainActor), (8) GDPR Article 17 "Delete All My Data" added with full store wipe. **Key medium fixes:** TelemetryDeck analytics added (DAU, conversion, retention), MetricKit crash reporting added, share cards include QR code + App Store link for attribution, widget layouts fully specified per size family (.systemSmall/.accessoryCircular/.systemMedium/.systemLarge), widget JSON extended with weeklyCompletions array, Data Management section always visible (never behind paywall), HealthKitModelActor uses UUID lookup (not persistentModelID).
>
> **Revision Notes (v3):** Targeted fixes from second 14-agent review. All 13 v1→v2 critical fixes confirmed correct. Key v3 changes: **5 new blockers fixed:** (B1) @Query dynamic date filtering replaced with ModelContext.fetch(FetchDescriptor) triggered by selectedDate changes, (B2) all ViewModels marked @Observable, (B3) fetchOrCreate upsert pattern added for HabitLog/MoodEntry to prevent duplicates, (B4) streak off-by-one fixed — starts from yesterday if today has no completed log, (B5) @ModelActor added for HealthKit background callbacks. **13 high-severity fixes:** HKStatisticsCollectionQuery replaced with per-type query strategy (HKSampleQuery for workouts/sleep), VersionedSchema conformance shape shown explicitly, StoreKit launch race fixed with optimistic isPremium, StaticConfiguration replaced with AppIntentConfiguration (iOS 17+), GDPR data export moved to free tier (Article 20 right to portability), GDPR consent collection flow added, age gate upgraded to date-of-birth entry (not binary yes/no), NSHealthShareUsageDescription string specified, CorrelationEngine filters by shouldAppear(on:), correlation thresholds lowered for binary/ordinal data, RuleEngine completionRate uses applicable days (not logged days), streak recovery logs marked isRecovered=true (distinguishable from real data), share cards moved to v1.0 MVP for viral loop. **Key medium fixes:** frequency as proper Swift enum with rawValue, bestStreak fully recomputed on deletion, #Index macro syntax (not @Attribute(.index)), widget JSON has schemaVersion field, activities use pipe delimiter (not comma), try context.save() with do/catch error handling, CorrelationEngine runs async with loading state, widget JSON debounced 300ms, StatsView progressive loading, "Smart" replaces "AI-powered", notification copy specified, App Store description expanded, time-of-day greetings consistent, journaling prompts expanded to 20+, reactivation notifications added, undo toast for accidental taps, energy score surfaced in insights, heat map uses fixed detail bar (not tooltip popover), binary habits use comparison bar chart (not scatter), free users told archiving frees slots, App Store Privacy Nutrition Labels specified, mental health disclaimer added, XCTest targets added, DebugDataGenerator added, confetti Canvas-based with 50-particle budget, export runs on Task.detached, streak notifications aggregated (not per-habit), reduced motion support, dark mode color tokens defined. **Timeline updated to 8-10 weeks** with explicit MVP cut line at Step 4. Steps 5 and 7 split into sub-steps.

---

## Navigation Architecture

DailyArc uses a flat tab-based navigation with 3 tabs (Today, Stats, Settings). Navigation patterns:

| Source | Destination | Method |
|--------|-------------|--------|
| Today tab | HabitFormView (add) | `.sheet` modal |
| Today tab | HabitFormView (edit) | `.sheet` modal (from swipe action) |
| Today tab | HabitManagementView | `NavigationLink` push |
| Stats tab | PerHabitDetailView | `NavigationLink` push |
| Stats tab | BadgesView | `NavigationLink` push |
| Stats tab | PaywallView | `.sheet` modal |
| Settings tab | All settings sub-views | `NavigationLink` push |
| Onboarding | Today tab | Root view swap (set `hasCompletedOnboarding`) |
| Widget deep link | Today/Stats tab | `onOpenURL` → set `selectedTab` |
| Celebration | Share sheet | `ShareLink` system sheet |
| Badge ceremony | Share sheet | `ShareLink` inside modal |

**Navigation stack:** Each tab owns its own `NavigationStack`. No cross-tab navigation — modals dismiss to their origin tab. `@AppStorage("selectedTab")` persists tab selection across launches. Widget deep links set tab via `onOpenURL`.

**Deep link routing table:**
| URL | Action | Source |
|-----|--------|--------|
| `dailyarc://today` | Select Today tab | SmallStreakWidget, MediumTodayWidget |
| `dailyarc://stats` | Select Stats tab + show "This Week" overlay | LargeStatsWidget, weekly summary notification |
| `dailyarc://settings/privacy` | Select Settings tab, push to Privacy section | Consent-related notifications |
| Unknown/malformed URL | Log to TelemetryDeck, ignore silently | Any |

**Deep link guard:** If `!hasCompletedOnboarding`, queue the deep link target and process after onboarding completes. Never navigate into the app before onboarding is done.

**Modal coordination strategy:** SwiftUI does not reliably stack multiple `.sheet` modifiers. Use a single `@State var activeSheet: SheetType?` enum on each tab's root view:
```swift
enum SheetType: Identifiable {
    case habitForm(Habit?)
    case paywall
    case badgeCeremony(Badge)
    case shareCard(ShareCardData)
    var id: String { /* unique per case */ }
}
```
Present via `.sheet(item: $activeSheet)`. Only one sheet active at a time. If a badge ceremony triggers while HabitFormView is open, queue it in `@State var pendingSheet: SheetType?` and present after the current sheet dismisses (via `.onDismiss`).

---

## Architecture Overview

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Language | Swift 5.9+ | Native performance, latest concurrency features |
| UI Framework | SwiftUI | Declarative, rapid iteration, native feel |
| Data Persistence | SwiftData with VersionedSchema | On-device storage, no server needed. VersionedSchema from day 1 for safe migrations. |
| Health Integration | HealthKit | Auto-log workouts, steps, sleep. **Never gated behind paywall — Apple will reject.** |
| Charts | Swift Charts | Native iOS 17+ charting (heat map, trend lines, sparklines) |
| AI Insights | **On-device RuleEngine ONLY** | Mood-habit correlations, personalized suggestions. **NO external API calls. NO Claude API. NO network requests for insights. Ever.** |
| Widgets | WidgetKit | Lock screen + home screen widgets. **NO Live Activities — habit tracking is not a real-time event.** |
| Architecture Pattern | MVVM (Views own @Query, **@Observable** ViewModels own business logic) | Clean separation, testable. @Query is a SwiftUI property wrapper — it cannot exist in @Observable classes. All ViewModels MUST be marked `@Observable`. |
| Monetization SDK | StoreKit 2 | One-time purchase IAP ($5.99) with Family Sharing enabled |
| Cloud Sync | CloudKit (private database) | **Deferred to v1.1.** Build local-first. |
| Analytics | TelemetryDeck (privacy-respecting) | DAU, feature adoption, conversion funnel, retention. No PII, differential privacy. |
| Crash Reporting | MetricKit (built-in) | Apple's native crash + hang + disk reporting. Zero third-party SDK. |
| Watch App | WatchKit + WatchConnectivity | **Deferred to v1.1.** Requires WatchConnectivity plumbing not yet specified. |

### Critical Architecture Decisions

1. **@Query lives in Views, NOT ViewModels.** `@Query` is a SwiftUI property wrapper that only works inside `View` structs. ViewModels use `@Observable` and receive data from Views or use `ModelContext` directly for writes. Views pass queried data to ViewModels via methods/properties.

2. **HabitLog uses @Relationship, NOT raw UUID.** `habitId: UUID` is replaced with a proper SwiftData `@Relationship` back to `Habit` for type safety, cascade deletes, and relationship integrity. The Habit model owns a `@Relationship(deleteRule: .cascade)` to its logs.

3. **Color stored as palette index, NOT SwiftUI Color.** `Color` is not `Codable` — SwiftData cannot persist it. Store as `colorIndex: Int` (0–9) into the fixed 10-color palette. Provide a computed `var color: Color` that reads `@Environment(\.colorScheme)` at call site and returns the appropriate light or dark hex. Legacy `colorHex` removed — a single index maps to both `hex` and `darkModeHex` in the palette array, guaranteeing correct appearance in both modes without storing two strings per habit.

4. **AI Insights are 100% on-device.** No Claude API. No external API calls of any kind. The app's brand advantage is "your habit and mood data never leaves your device." All insights use RuleEngine (rule-based logic) + on-device Pearson correlation statistics. CoreML can be evaluated for v1.1 mood prediction if demand warrants it.

5. **VersionedSchema from Day 1.** All `@Model` classes are **nested inside** the `DailyArcSchemaV1` enum conforming to `VersionedSchema`. Type-alias them at module scope for convenience (`typealias Habit = DailyArcSchemaV1.Habit`). Any v1.1 model change uses `SchemaMigrationPlan` with a `MigrationStage`. Without this, model changes crash existing users.

6. **Mood and habit logging are decoupled.** Habit completions auto-save on tap (no "Save Today's Log" button for habits). Mood logging is independent and optional — users can log habits without logging mood, and vice versa. This eliminates the biggest UX friction and prevents data loss if the app backgrounds.

7. **Date normalization uses device Calendar.** All dates are normalized to start-of-day using `Calendar.current.startOfDay(for: date)`. Streak cutoff respects the user's timezone via `Calendar.current`. No hardcoded UTC assumptions. **Timezone strategy:** Capture `let userCalendar = Calendar.current` once per session (in `DailyArcApp.onAppear` or equivalent) and pass it to StreakEngine, CorrelationEngine, RuleEngine, and WidgetDataService via their `calendar:` parameters. This prevents mid-session inconsistencies if the user crosses a timezone boundary while the app is foregrounded. On `.scenePhase == .active`, re-capture `userCalendar` to pick up timezone changes that occurred while backgrounded.

8. **Streak values are cached on the Habit model.** `currentStreak: Int` and `bestStreak: Int` are stored properties on `Habit`, invalidated and recalculated only when a new HabitLog is saved or deleted. This avoids O(n) recalculation on every view load. **Cold-launch reconciliation:** On first `.onAppear` of TodayView (deferred to after first frame via `task { }`), verify all cached streaks by calling `streakEngine.recalculateStreaks(for:logs:isDeletion:false, isFirstCallToday:true, calendar:)` for each habit. This catches stale caches from: (a) app killed during debounce window, (b) day boundary crossing while suspended, (c) timezone changes. Run asynchronously — display cached values immediately, update if reconciliation finds a discrepancy.

9. **DaySnapshot is batch-computed.** A single query fetches all HabitLogs for a date range, then groups in-memory by date. Never compute 365 individual DaySnapshots with separate queries — that causes 365+ round trips to SwiftData.

10. **Heat map uses Canvas, NOT 365 SwiftUI views.** SwiftUI views are expensive; a Canvas (or LazyHGrid with recycling) renders the year heat map in a single draw pass. Tap hit-testing uses coordinate math.

11. **HealthKit data NEVER leaves the device.** All HealthKit-sourced HabitLog entries have `isAutoLogged = true`. These are excluded from any hypothetical future API payloads. Apple prohibits sharing HealthKit data with third parties without explicit consent and strict controls.

12. **HealthKit sync is ongoing, not just initial backfill.** Use `HKObserverQuery` for real-time updates when new health data arrives. The initial 30-day backfill uses `HKStatisticsCollectionQuery` (not raw sample queries returning thousands of rows).

13. **Do NOT use `#Unique` macro on any model property.** It breaks CloudKit compatibility silently (deferred to v1.1 but plan ahead).

14. **No Live Activities.** Habit tracking is not a real-time event. Live Activities with a 2-second timer drain battery and misuse the platform. Removed entirely.

15. **Watch app deferred to v1.1.** Requires WatchConnectivity plumbing, data transfer protocol, and background refresh scheduling that are not yet specified. Ship phone app first.

16. **Widget data is pre-computed in the main app.** Widget extensions should NOT run SwiftData queries directly. The main app writes a lightweight JSON payload to `UserDefaults(suiteName: "group.com.dailyarc.shared")` containing today's completion %, top streak, and mood. The widget reads this JSON. **Version mismatch fallback:** If the widget extension reads a `schemaVersion` higher than it understands (e.g., during staged rollout), fall back to a minimal display: app icon + "Open DailyArc" text. Never crash on unknown schema. Wrap JSON parsing in do/catch and return a safe default timeline entry on any error. **Migration handler:** When the app writes schemaVersion N and the widget knows versions 1..N-1, the widget must: (1) attempt to parse known fields from the JSON ignoring unknown keys (`JSONDecoder` with `.ignoreUnknownKeys` in Swift 5.9+), (2) if a required field is missing, use safe defaults (`completionPercent: 0`, `moodEmoji: ""`), (3) log the mismatch via `os_log` for debugging. The app is responsible for backward-compatible JSON: new fields are additive, existing fields never change type or meaning.

17. **HealthKit is NEVER gated behind the paywall.** Apple may reject apps that require payment for HealthKit features. HealthKit integration is free for all users. Premium gates: AI correlation insights, detailed trend analysis, unlimited habits (free tier: 3 habits).

18. **Notification permissions are requested on first toggle, not on app launch.** When the user enables any notification toggle for the first time, call `UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])`. Don't front-load the permission request during onboarding.

19. **Accessibility is baked into every step, not deferred.** Each build step includes accessibility requirements inline. The final step is the audit/polish pass, not the first time accessibility is considered.

19b. **iPad support (v1.0): best-effort, not optimized.** **Minimum viable iPad presentation:** When `horizontalSizeClass == .regular`, constrain content to a maximum width of 500pt, centered horizontally with `backgroundPrimary` fill on either side. This prevents the "stretched phone" appearance on iPad without requiring a full adaptive layout. Implementation: wrap the root `ContentView` body in a `frame(maxWidth: 500)` when size class is `.regular`. DailyArc is portrait-locked for iPhone (see rule 35). iPad runs via "Designed for iPhone" compatibility mode. Known acceptable degradations: (1) heat map may require horizontal scroll in compact width, (2) confetti Canvas fills available width (may look sparse), (3) onboarding pages may have excessive whitespace. Landscape and native iPad optimization deferred to v1.1 — at that point, remove the portrait lock and implement adaptive layouts. Add iPad optimization to v1.1 backlog if App Store analytics show >5% iPad installs.

20. **All ViewModels MUST be marked `@Observable`.** Without the `@Observable` macro, SwiftUI won't track property changes and the UI won't update. Every ViewModel class declaration: `@Observable class TodayViewModel { ... }`.

21. **Date-based queries use ModelContext.fetch, NOT dynamic @Query.** `@Query` predicates are compile-time constants — you cannot bind them to a `@State var selectedDate`. For date navigation, use `ModelContext.fetch(FetchDescriptor<HabitLog>(predicate: #Predicate { $0.date == selectedDate }))` triggered by `.onChange(of: selectedDate)`. Static @Query is used for non-date-filtered data (all habits, all non-archived habits).

22. **fetchOrCreate upsert pattern for all log writes.** Without `#Unique` (avoided for CloudKit), rapid tapping creates duplicate HabitLogs. Every auto-save MUST call `fetchOrCreate(habit:date:context:)` which queries first and updates `count` if found, or creates a new log if not. Same pattern for MoodEntry: `fetchOrCreateMood(date:context:)`.

23. **Streak calculation treats today as "in progress."** If today has no completed log yet (user hasn't logged), start counting from yesterday. Otherwise users see "🔥 0" every morning despite a 100-day streak. Logic: `let startDate = todayHasCompletedLog ? today : yesterday`.

24. **HealthKit background callbacks use @ModelActor.** `HKObserverQuery` fires on a background queue. `ModelContext` is NOT thread-safe. All SwiftData writes from HealthKit callbacks MUST go through a `@ModelActor` service or `await MainActor.run { ... }`. Never write to ModelContext from a background queue directly.

25. **HealthKit uses per-type query strategy.** `HKStatisticsCollectionQuery` works for quantity types (steps, distance) but NOT for workouts or sleep (category/workout types). Use `HKSampleQuery` for workouts AND for sleep (`HKCategoryQuery` does not exist — use `HKSampleQuery` with `HKCategoryType(.sleepAnalysis)` predicate, filtering for `.inBed` or `.asleepUnspecified`). The HealthKitService must dispatch to the correct query type based on `healthKitTypeRaw`.

26. **Streak recovery logs are marked `isRecovered = true`.** Recovery-backfilled HabitLogs are distinguishable from real completions. **isRecovered logs DO count toward streak calculations** (that's the whole point of recovery). Only CorrelationEngine and RuleEngine exclude `isRecovered == true` logs from statistical/insight calculations to prevent data corruption.

27. **Export (JSON/CSV) is FREE for GDPR compliance.** GDPR Article 20 grants a right to data portability that cannot be gated behind a paywall. Basic JSON export is available to all users. Premium adds formatted CSV export and import functionality.

28. **"Delete All My Data" for GDPR Article 17 (Right to Erasure).** Settings includes a destructive "Delete All My Data" button that wipes all SwiftData stores, all UserDefaults keys, and resets the app to first-launch state. Required for App Store approval when collecting personal data.

29. **Auto-save writes are debounced 300ms.** Rapid habit tapping can create 10+ SwiftData writes, each triggering @Query observation updates. A 300ms debounce on `context.save()` coalesces rapid taps into a single write.

30. **Confetti is Canvas-based with a 50-particle budget.** Not individual animated SwiftUI views. Respects `AccessibilityEnvironment.isReduceMotionEnabled` — when enabled, show a static "All done! ✅" banner instead of particles.
Particle visual spec (see authoritative confetti spec in Celebration Intensity Escalation section): particle size 8-14pt random, shapes: 60% rectangles (4:1 aspect), 30% circles, 10% habit emoji; colors: brand palette (Sky, Coral, Indigo, premiumGold) at random; velocity: initial burst 400-800pt/s upward with 120° spread, gravity 600pt/s², rotation: random 0-720°/s; fade: alpha 1.0→0.0 over final 0.5s. Dark mode: particle opacity 0.85 (not 1.0). Canvas-rendered, NOT SwiftUI views. Preview confetti (onboarding Page 3): 15-particle burst (30% of full), 1-second duration, no haptic — lighter than real celebration to create anticipation.

31. **Mental health disclaimer required.** Settings must include: "DailyArc is not a medical device. If you are experiencing mental health concerns, please consult a healthcare professional." Required for App Store Health & Fitness category.

32. **Privacy-respecting analytics via TelemetryDeck.** No user PII, no tracking IDs, differential privacy by default. Track: daily active users, feature adoption (HealthKit %, premium conversion rate, widget usage), onboarding completion rate, retention (day 1/7/30). Configure in `DailyArcApp.swift` on launch. **ATT determination: NOT required.** TelemetryDeck uses no IDFA, no device fingerprinting, and no cross-app tracking — it relies on differential privacy with anonymous signals. Per Apple's ATT documentation, ATT prompt is only required when tracking users across apps/websites owned by other companies. TelemetryDeck's architecture explicitly avoids this. Add note to privacy policy: "We use privacy-respecting analytics (TelemetryDeck) that do not track you across apps or websites."

33. **Keyboard dismissal strategy.** All ScrollViews use `.scrollDismissesKeyboard(.interactively)`. All text fields with multi-line input (mood notes, habit notes) show a toolbar "Done" button via `.toolbar { ToolbarItemGroup(placement: .keyboard) { Button("Done") { focusedField = nil } } }`. Habit form name field dismisses on Return key.

34. **Crash reporting + performance monitoring via MetricKit.** Apple's built-in crash and performance reporting — no third-party SDK needed. Collect crash logs, hang reports, and disk write diagnostics. Zero privacy impact. Supplement with Xcode Organizer crash reports from TestFlight and App Store builds.

**PerformanceMonitoringService (Services/PerformanceMonitoringService.swift):**
Subscribes to `MXMetricManager` for comprehensive performance monitoring beyond crash reporting:
- `MXAppLaunchMetric`: validates <1.0s cold launch target. Alert if p95 exceeds 1.5s.
- `MXScrollingMetric`: validates <5ms hitch rate. Log to TelemetryDeck if degraded.
- `MXHangDiagnostic`: validates <100ms hang target. Forward hang stacks for debugging.
- `MXDiskWriteMetric`: monitors DebouncedSave write patterns. Alert if excessive.
- `MXAppExitMetric`: tracks background termination reasons (memory pressure, watchdog).
Implementation: `class PerformanceMonitoringService: NSObject, MXMetricManagerSubscriber`. Register in `DailyArcApp.init()`. Parse `didReceive(_:)` payloads and forward aggregated metrics to TelemetryDeck (if analytics enabled) or log locally. No user consent required — MetricKit is Apple's built-in system with no PII.

35. **Portrait orientation only for v1.0.** Lock to portrait via Info.plist `UISupportedInterfaceOrientations` = `UIInterfaceOrientationPortrait` only. The heat map, habit list, and mood check-in are designed for portrait viewport. Landscape support deferred to v1.1 alongside iPad optimization.

36. **Build with Xcode 16.0+ (Swift 6.0) with `-strict-concurrency=complete`.** The spec uses `@preconcurrency import`, `@Sendable` closures, and `@ModelActor` patterns that require Swift 6. Pin minimum Xcode version in the project README and CI configuration. This catches all Sendable violations at compile time rather than discovering them post-ship.

37. **CI/CD is a Day 1 prerequisite, not a pre-launch checklist item.** Configure Xcode Cloud (recommended for solo developer — integrated with App Store Connect) or GitHub Actions before writing Step 1 code. Pipeline: PR builds run `xcodebuild test` on iOS 17.4 simulator; merge-to-main triggers archive + TestFlight upload. Performance tests (`PerformanceTests.swift`) should NOT run on CI unless using Xcode Cloud's consistent hardware (baselines are machine-dependent).

38. **SPM is the sole dependency manager.**

39b. **Use SwiftUI environment values, NOT UIKit statics, for accessibility and platform APIs.** Replace `UIAccessibility.isReduceMotionEnabled` with `@Environment(\.accessibilityReduceMotion)`. Replace `UIAccessibility.isVoiceOverRunning` with `@Environment(\.accessibilityEnabled)`. Replace `UIDevice.current.systemVersion` with `ProcessInfo.processInfo.operatingSystemVersionString`. Wrap `UIApplication.shared` calls behind a `BackgroundTaskService` protocol. These SwiftUI equivalents work on iOS, macOS, and visionOS — UIKit statics do not exist on visionOS. **`AccessibilityEnvironment` helper:** For code outside Views (ViewModels, services) that needs accessibility state, create a lightweight `@Observable class AccessibilityEnvironment` that captures values from the SwiftUI environment and is injectable:
```swift
@Observable class AccessibilityEnvironment {
    static let shared = AccessibilityEnvironment()
    var isReduceMotionEnabled = false
    var isVoiceOverRunning = false  // Maps to @Environment(\.accessibilityEnabled) on visionOS — see note below
    var isDifferentiateWithoutColorEnabled = false
    // Updated from root ContentView via .onChange(of:) on @Environment values:
    // .onChange(of: accessibilityReduceMotion) { AccessibilityEnvironment.shared.isReduceMotionEnabled = $0 }
    // .onChange(of: accessibilityEnabled) { AccessibilityEnvironment.shared.isVoiceOverRunning = $0 }
    // .onChange(of: accessibilityDifferentiateWithoutColor) { AccessibilityEnvironment.shared.isDifferentiateWithoutColorEnabled = $0 }
    //
    // NOTE: @Environment(\.accessibilityEnabled) fires for VoiceOver, Switch Control, Voice Control,
    // and other assistive technologies — not just VoiceOver. For VoiceOver-specific behavior (toast
    // 6-second timing), this is acceptable: all AT users benefit from extended dismiss timers.
    // If VoiceOver-only behavior is needed in v2.0+ (visionOS), use #if canImport(UIKit) guard with
    // UIAccessibility.isVoiceOverRunning fallback.
}
```
Pass this to StreakEngine, ConfettiRenderer, and analytics configuration instead of reading UIKit statics directly.

40. **Memory pressure handling uses NotificationCenter, not UIApplication directly.** Register for `.memoryWarning` via `NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification)` — wrap in `#if canImport(UIKit)` for visionOS/macOS portability. Add TelemetryDeck via Swift Package Manager. No CocoaPods, no Carthage. The project has exactly one third-party dependency. This is a design principle: minimize external risk.

39. **Automated on-device backup via iCloud Drive container.** Schedule a `BGAppRefreshTask` that copies the SwiftData SQLite file to a dated backup in the app's iCloud Drive ubiquity container (`FileManager.default.url(forUbiquityContainerIdentifier:)`), retaining the last 3 copies. On `ModelContainer` failure, offer "Restore from Backup" as a third option alongside "Try to Repair" and "Reset App." This requires no CloudKit schema and preserves the on-device-only privacy promise. Backup frequency: weekly or on every 100th habit log, whichever comes first. **WAL checkpoint before backup (CRITICAL):** SwiftData uses SQLite in WAL mode — recent writes live in the `-wal` file, not the main `.sqlite` file. Before copying, perform a WAL checkpoint to flush all data to the main file. Use `FileManager` to copy all three files atomically (`.sqlite`, `.sqlite-wal`, `.sqlite-shm`), OR use the SQLite C API: `sqlite3_wal_checkpoint_v2(db, nil, SQLITE_CHECKPOINT_TRUNCATE, nil, nil)` before copying just the `.sqlite` file. Verify post-copy that no `-wal` file exists alongside the backup (confirming checkpoint succeeded). Log `backup_wal_size_bytes` to TelemetryDeck for monitoring.

---

## Free vs Premium Tier

| Feature | Free | Premium ($5.99) |
|---------|------|-----------------|
| Habits | Up to 3 | Unlimited |
| Mood logging | ✓ | ✓ |
| Habit logging & streaks | ✓ | ✓ |
| HealthKit auto-logging | ✓ | ✓ |
| Basic stats (heat map, per-habit cards) | ✓ | ✓ |
| Basic RuleEngine suggestions (4 rules) | ✓ | ✓ |
| Mood-habit correlation insights | — | ✓ |
| Full smart suggestions (12+ rules) | — | ✓ |
| Detailed trend analysis | — | ✓ |
| Basic JSON export (GDPR portability) | ✓ | ✓ |
| Formatted CSV export + import | — | ✓ |
| Medium & large home screen widgets | — | ✓ |
| Small lock screen widget | ✓ | ✓ |

---

## Data Model

### CRITICAL: All `@Model` classes NESTED inside `DailyArcSchemaV1` enum conforming to `VersionedSchema`. Use `typealias Habit = DailyArcSchemaV1.Habit` at module scope for convenience.

### Habit
| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier (auto-generated) |
| name | String | Habit name (e.g., "Exercise") |
| emoji | String | Visual icon for the habit (e.g., "🏃") |
| colorIndex | Int | Index (0–9) into `HabitColorPalette.colors` array. **NOT Color — Color is not Codable.** Default 5 (Sky). |
| frequencyRaw | Int | **Backed by `HabitFrequency` Swift enum** (see below). Stored as rawValue for SwiftData. 0=daily, 1=weekdays, 2=weekends, 3=custom |
| customDays | String | **Pipe-delimited** day indices "0|2|4" when frequency==.custom. Empty string otherwise. **[Int] is not directly persistable in SwiftData; use String + computed accessor. Uses `|` not `,` to avoid delimiter collisions.** |
| targetCount | Int | Completions per day (1–10, default 1) |
| reminderTime | Date? | Optional notification time |
| reminderEnabled | Bool | Whether notifications are active (default false) |
| healthKitTypeRaw | String? | Optional HealthKit metric identifier (e.g., "HKQuantityTypeIdentifierStepCount") |
| autoLogHealth | Bool | Auto-log from HealthKit data (default false) |
| startDate | Date | When habit tracking began |
| isArchived | Bool | Soft delete flag (default false) |
| sortOrder | Int | User-defined display order |
| currentStreak | Int | **Cached** current streak (recalc on log save/delete) |
| bestStreak | Int | **Cached** best streak ever (recalc on log save/delete) |
| createdAt | Date | Creation timestamp |
| logs | [HabitLog] | **@Relationship(deleteRule: .cascade)** — one-to-many |

**HabitFrequency enum (define alongside model):**
```swift
// SCHEMA CONTRACT: Append-only. Never reorder or remove cases — raw values are persisted in SwiftData.
enum HabitFrequency: Int, Codable, CaseIterable {
    case daily = 0
    case weekdays = 1
    case weekends = 2
    case custom = 3
}
```

**Computed properties:**
```swift
/// Type-safe frequency accessor
var frequency: HabitFrequency {
    get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
    set { frequencyRaw = newValue.rawValue }
}

/// Color accessor — resolves palette index to Color based on colorScheme at call site
/// Usage in View: habit.color(for: colorScheme) where colorScheme is from @Environment(\.colorScheme)
func color(for scheme: ColorScheme) -> Color {
    let entry = HabitColorPalette.colors[safe: colorIndex] ?? HabitColorPalette.colors[5]
    return Color(hex: scheme == .dark ? entry.darkModeHex : entry.hex) ?? .blue
}

/// Parse customDays string to [Int] — uses pipe delimiter (not comma)
var customDayIndices: [Int] {
    guard frequency == .custom, !customDays.isEmpty else { return [] }
    return customDays.split(separator: "|").compactMap { Int($0) }
}

/// Check if habit should appear on a given date.
/// Delegates to DateHelpers.shouldAppear — do NOT duplicate weekday logic here.
/// `calendar` parameter REQUIRED — caller must pass Calendar.current captured on @MainActor.
/// Prevents timezone bugs when called from non-main contexts.
func shouldAppear(on date: Date, calendar: Calendar) -> Bool {
    DateHelpers.shouldAppear(on: date, frequencyRaw: frequencyRaw, customDays: customDays, calendar: calendar)
}
// NOTE: `calendar` is intentionally required (no default). This turns silent Calendar.current
// misuse in background contexts into a compile-time error. Callers on @MainActor pass their
// captured calendar; callers in Task.detached must explicitly provide one.
```

### HabitLog
| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier |
| habit | Habit? | **@Relationship — back-reference to parent Habit. NOT a raw UUID.** |
| habitIDDenormalized | UUID | **Stored copy of `habit.id` — set on creation, enables compound `#Index` and avoids optional-chaining in `#Predicate`. MUST keep in sync: set on creation, update if habit reassigned.** |
| date | Date | Which day (normalized to start of day via `Calendar.current.startOfDay`) |
| count | Int | Completions on this day (0 to habit.targetCount) |
| notes | String | Optional user notes (default empty string) |
| isAutoLogged | Bool | True if sourced from HealthKit (default false) |
| isRecovered | Bool | **True if created by streak recovery.** Excluded from correlation/rule calculations. (default false) |
| createdAt | Date | Log entry timestamp |

**CRITICAL: Index the `date` property using the `#Index` macro on the model (NOT `@Attribute(.index)` which doesn't compile).** SwiftData uses `#Index` at the `@Model` level:
```swift
@Model
class HabitLog {
    // ... properties ...
}
// On the model declaration, add:
// #Index<HabitLog>([\.date])
// **Recommended: denormalized habitID for indexing.** Add `var habitIDDenormalized: UUID` stored
// property on HabitLog, set to `habit.id` on creation. This enables a true compound index:
// #Index<HabitLog>([\.date, \.habitIDDenormalized])
// Rationale: SwiftData #Index has limited support for relationship keypaths in compound indexes.
// A denormalized UUID avoids optional-chaining issues in #Predicate and enables fetchLimit=1
// queries on the critical tap path (fetchOrCreate). Keep it in sync: set on creation, update
// if habit is ever re-assigned (unlikely for v1.0). Falls back to single #Index on \.date if
// the compound index causes issues — use Dictionary(grouping:) at app level.
// #Index requires iOS 17.4+ (which is our minimum target).
```

**Race condition mitigation (SOLVED in v28 — single-writer architecture):** Prior to v28, the main actor and a separate HealthKitModelActor both called fetchOrCreate on separate ModelContexts. This is now eliminated: ALL writes route through HabitLogWriteActor (see line ~429). **Defense-in-depth layers (retained as safety net):**
1. HabitLogWriteActor single-writer guarantees no concurrent writes
2. DedupService foreground scan (periodic, batch)
3. Cold-launch streak reconciliation (catches stale caches)
4. **Data integrity validator (cold launch, after DedupService):** Runs once per cold launch after DedupService completes. Budget: <200ms, same bail-on-timeout pattern. Validates:
   - (a) All HabitLogs have `habitIDDenormalized` matching their `habit?.id` relationship (fix by re-syncing if mismatched)
   - (b) No orphaned HabitLogs exist whose parent Habit was deleted (delete orphans)
   - (c) Cached `currentStreak` and `bestStreak` values are consistent with actual log data (recalculate if inconsistent — limited to 3 habits per launch cycle to stay in budget)
   Log any corrections to TelemetryDeck (`data_integrity_fix` with fix type and count).
**v1.0 REQUIREMENT (upgraded from v1.1):** Route ALL HabitLog and MoodEntry writes through a single `@ModelActor` (`HabitLogWriteActor`) to eliminate the dual-context race entirely. The main context becomes read-only for log/mood writes; taps dispatch to `HabitLogWriteActor.shared.save(habit:date:count:calendar:)`. This eliminates the race condition at the source rather than patching it reactively with dedup. DebouncedSave debounces the *dispatch* to the actor, not the save itself. The HealthKitModelActor is folded into this single write actor.

**HabitLogWriteActor code definition (Services/HabitLogWriteActor.swift):**
```swift
@ModelActor
actor HabitLogWriteActor {
    static let shared: HabitLogWriteActor = { /* init with ModelContainer */ }()

    /// Create or update a HabitLog — the single write path for all log mutations
    func saveLog(habitID: UUID, date: Date, count: Int, isAutoLogged: Bool = false, isRecovered: Bool = false, calendar: Calendar) throws {
        let normalizedDate = calendar.startOfDay(for: date)
        var descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { $0.date == normalizedDate && $0.habitIDDenormalized == habitID }
        )
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            existing.count = isAutoLogged ? max(existing.count, count) : count
        } else {
            let log = HabitLog(/* ... */)
            modelContext.insert(log)
        }
        try modelContext.save()
    }

    /// Create or update a MoodEntry
    func saveMood(date: Date, moodScore: Int, energyScore: Int, activities: String, notes: String, calendar: Calendar) throws {
        // fetchOrCreate pattern for MoodEntry
        try modelContext.save()
    }

    /// Commit pending changes — called by DebouncedSave after debounce timer
    func commitPendingChanges() throws {
        try modelContext.save()
    }
}
```
**Automated circuit breaker:** If `dedup_correction_count / total_save_count > 0.5%` in any 24-hour window (measured via TelemetryDeck), log `write_race_detected` as a P0 alert. This should never trigger with the single-actor architecture but serves as a safety net.

**CRITICAL: fetchOrCreate upsert pattern — prevents duplicate logs on rapid tapping:**
```swift
/// Fetch existing log or create new one. NEVER create without checking first.
/// NOTE: #Predicate has limited support for persistentModelID in iOS 17.
/// Use date-only predicate + post-fetch filter by habit identity for reliability.
///
/// NOTE (v28): With the HabitLogWriteActor single-writer architecture, dual-context races
/// should not occur. DedupService is retained as defense-in-depth only.
///     Implementation: DedupService.swift — runs once per app foreground (gated by @AppStorage("lastDedupDate"),
///     skip if <1 hour since last run). Algorithm:
///     1. Fetch HabitLogs from the last 30 days (#Predicate { $0.date >= thirtyDaysAgo }) — NOT "fetch all"
///        (unbounded scan contradicts <200ms budget for long-term users. 30-day window is authoritative.)
///     2. Sort by (habitIDDenormalized, date) — O(N log N). Walk sorted array comparing consecutive entries.
///        When consecutive entries share the same (habitIDDenormalized, startOfDay(date)): keep log with highest count, delete rest.
///     3. For MoodEntry dedup: sort by date, walk, compare consecutive startOfDay(date) — keep latest createdAt.
///     4. Save once after all deletions
///     Budget: <200ms for 30 days of data. If processing exceeds 200ms (measured via
///     `ContinuousClock`), bail after current batch and defer remainder to next foreground cycle.
///     Log timeout count and dedup count to TelemetryDeck.
///     Added to Build Step 8 (polish).
static func fetchOrCreate(habit: Habit, date: Date, context: ModelContext, calendar: Calendar) -> HabitLog {
    let normalizedDate = calendar.startOfDay(for: date)
    let habitID = habit.id
    var descriptor = FetchDescriptor<HabitLog>(
        predicate: #Predicate { $0.date == normalizedDate && $0.habitIDDenormalized == habitID }
    )
    // NOTE: Uses habitIDDenormalized (stored UUID) instead of $0.habit?.id (optional-chain through
    // @Relationship). The denormalized field enables the compound #Index and avoids optional-chaining
    // issues in #Predicate that can cause missed matches when the relationship is not yet faulted in.
    descriptor.fetchLimit = 1  // Exact match on habit+date — at most 1 exists

    if let existing = (try? context.fetch(descriptor))?.first {
        return existing
    }
    let newLog = HabitLog(date: normalizedDate, count: 0)
    newLog.habit = habit
    newLog.habitIDDenormalized = habit.id  // CRITICAL: populate denormalized field for compound index
    context.insert(newLog)
    return newLog
}
```

### MoodEntry
| Property | Type | Description |
|----------|------|-------------|
| id | UUID | Unique identifier |
| date | Date | Which day (normalized to start of day) |
| moodScore | Int | 1–5 scale (😔=1, 😕=2, 😐=3, 🙂=4, 😄=5) |
| energyScore | Int | 1–5 scale (very low to very high). **Sentinel: 0 = "not yet logged"** (distinct from 1 = "very low"). UI shows energy picker in unselected state when 0. CorrelationEngine and RuleEngine MUST filter entries where energyScore == 0 from energy analysis. Same sentinel pattern as moodScore. |
| activities | String | **Pipe-delimited tags** (e.g., "socializing|exercise|work"). **Uses `|` not `,` to avoid breaking on commas in custom tags.** [String] is not directly persistable; use String + computed accessor. |
| notes | String | Optional journal entry (default empty string) |
| createdAt | Date | Entry timestamp |

**CRITICAL: Index `date` using `#Index` macro (same pattern as HabitLog). Add `#Index<MoodEntry>([\.date])` on model.**

**CRITICAL: fetchOrCreate upsert for MoodEntry:**
```swift
/// fetchOrCreate for MoodEntry. Signature: `fetchOrCreate(date:context:calendar:)`.
/// The `calendar:` parameter is REQUIRED for date normalization consistency (same pattern as
/// HabitLog.fetchOrCreate — never use `Calendar.current` implicitly inside fetchOrCreate).
/// IMPORTANT: New entries use moodScore: 0 and energyScore: 0
/// as sentinel values meaning "not yet set." The UI MUST check for 0 and treat it as unselected
/// (showing no emoji highlighted). This prevents central tendency bias — defaulting to 3 would
/// skew correlation data toward neutral even when the user hasn't made a choice.
static func fetchOrCreate(date: Date, context: ModelContext, calendar: Calendar) -> MoodEntry {
    let normalizedDate = calendar.startOfDay(for: date)
    var descriptor = FetchDescriptor<MoodEntry>(
        predicate: #Predicate { $0.date == normalizedDate }
    )
    descriptor.fetchLimit = 1
    if let existing = try? context.fetch(descriptor).first {
        return existing
    }
    let newEntry = MoodEntry(date: normalizedDate, moodScore: 0, energyScore: 0)
    context.insert(newEntry)
    return newEntry
}
```

**Computed property:**
```swift
/// Parse activities string to [String] — pipe-delimited
var activityList: [String] {
    guard !activities.isEmpty else { return [] }
    return activities.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }
}
/// Sanitize and add a custom activity tag — strips pipe delimiter, trims, caps length
func addActivity(_ tag: String) {
    let sanitized = tag.replacingOccurrences(of: "|", with: "").trimmingCharacters(in: .whitespaces).prefix(30)
    guard !sanitized.isEmpty else { return }
    var list = activityList
    list.append(String(sanitized))
    activities = list.joined(separator: "|")
}

/// Mood emoji for display. Returns empty string for unset sentinel (moodScore == 0).
/// Callers MUST check for empty string and treat as "no mood logged" in UI.
var moodEmoji: String {
    switch moodScore {
    case 0: return ""   // Sentinel: not yet set — show no emoji, not neutral
    case 1: return "😔"
    case 2: return "😕"
    case 3: return "😐"
    case 4: return "🙂"
    case 5: return "😄"
    default: return ""  // Out of range — treat as unset
    }
}
```

### DaySnapshot (Computed struct — NOT a @Model)
| Property | Type | Description |
|----------|------|-------------|
| date | Date | The day |
| completedHabits | Int | Habits where log.count >= habit.targetCount |
| totalHabits | Int | Total habits active on this day |
| completionPercentage | Double | completedHabits / totalHabits (0.0 if totalHabits == 0) |
| moodEntry | MoodEntry? | Mood data for the day (optional) |

**CRITICAL: Batch-compute snapshots.** Fetch all HabitLogs for date range in ONE query, group by date in memory:
```swift
/// CORRECT: Single query + in-memory grouping
func snapshots(from startDate: Date, to endDate: Date, habits: [Habit], logs: [HabitLog], moods: [MoodEntry], calendar: Calendar) -> [DaySnapshot] {
    let logsByDate = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.date) }
    let moodsByDate = Dictionary(grouping: moods) { calendar.startOfDay(for: $0.date) }

    var result: [DaySnapshot] = []
    var current = startDate
    while current < endDate {
        let dayLogs = logsByDate[current] ?? []
        let activeHabits = habits.filter { !$0.isArchived && $0.shouldAppear(on: current, calendar: calendar) && $0.startDate <= current }
        let completed = activeHabits.filter { habit in
            dayLogs.first(where: { $0.habitIDDenormalized == habit.id })?.count ?? 0 >= habit.targetCount
        }.count
        let total = activeHabits.count
        result.append(DaySnapshot(
            date: current,
            completedHabits: completed,
            totalHabits: total,
            completionPercentage: total > 0 ? Double(completed) / Double(total) : 0,
            moodEntry: moodsByDate[current]?.first
        ))
        current = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
    }
    return result
}
```

### Color Palette (10 colors — contrast-tested for both light and dark backgrounds)

**IMPORTANT:** Gold, Mint, and Teal from v2 failed WCAG AA contrast on light backgrounds. Replaced with darker variants. All colors below pass 4.5:1 contrast ratio against both white and black backgrounds.

```swift
enum HabitColorPalette {
static let colors: [(name: String, hex: String, darkModeHex: String)] = [
    ("Coral",   "#E63946", "#FF6B6B"),   // darker on light, lighter on dark
    ("Orange",  "#E76F00", "#FF9F43"),
    ("Amber",   "#C68400", "#E8A317"),   // replaced Gold — passes contrast
    ("Green",   "#2D8A4E", "#48C78E"),   // replaced Mint — passes contrast
    ("Teal",    "#0077A8", "#0ABDE3"),   // darkened for light mode
    ("Sky",     "#2563EB", "#54A0FF"),
    ("Indigo",  "#5F27CD", "#8B5CF6"),
    ("Violet",  "#7C3AED", "#A66DD4"),
    ("Rose",    "#DB2777", "#F472B6"),
    ("Slate",   "#475569", "#94A3B8")
]
}
```

**Dark mode token system:** Use `darkModeHex` when `colorScheme == .dark`. Define as SwiftUI `Color` asset catalog entries or use the `@Environment(\.colorScheme)` adaptive pattern.

**Dark mode as brand expression:** Dark mode is not just "inverted colors" — it's a distinct visual personality. **Brand intent:** Dark mode is "intimate evening reflection" — quieter, more focused, premium-feeling. In dark mode: (1) backgrounds use true black (`#000000`) for OLED efficiency and depth, (2) cards use `#1C1C1E` (elevated surface) with subtle 1pt `separator` border for depth, (3) accent colors shift brighter (see adaptive tokens above), (4) the arc motif glow effect (onboarding, celebrations) uses a soft radial gradient (`accentColor` at 15% opacity) that is more visible on dark backgrounds, creating a premium nighttime feel, (5) confetti particles use slightly reduced opacity (0.85 vs 1.0 in light mode) for a softer celebration aesthetic, (6) streak fire emoji glow is more pronounced on dark backgrounds. Dark mode should feel like the "evening edition" of DailyArc — every interaction should feel intentional and reflective, not just functional.

### Design Tokens (Semantic Colors, Typography, Spacing, Animation)

**Semantic UI Colors (beyond habit colors — for chrome, text, feedback):**
```swift
enum DailyArcTokens {
    // Backgrounds (hex equivalents for design handoff: light / dark)
    static let backgroundPrimary = Color(.systemBackground)          // #FFFFFF / #000000
    static let backgroundSecondary = Color(.secondarySystemBackground) // #F2F2F7 / #1C1C1E (grouped cards)
    static let backgroundTertiary = Color(.tertiarySystemBackground)   // #FFFFFF / #2C2C2E (nested cards)

    // Text (hex equivalents for design handoff: light / dark)
    static let textPrimary = Color(.label)                           // #000000 / #FFFFFF
    static let textSecondary = Color(.secondaryLabel)                // #3C3C43@60% / #EBEBF5@60%
    static let textTertiary = Color(.tertiaryLabel)                  // #3C3C43@30% / #EBEBF5@30%

    // Borders & Separators (hex equivalents: light / dark)
    static let separator = Color(.separator)                         // #3C3C43@29% / #545458@65%
    static let border = Color(.systemGray4)                          // #D1D1D6 / #3A3A3C

    // Feedback States — ADAPTIVE (automatic light/dark switching via Color extension)
    // Color extension `init(light:dark:)` reads @Environment(\.colorScheme) internally.
    // Alternatively, define in Asset Catalog with "Any/Dark" appearance variants.
    // All pairs verified WCAG AA 4.5:1 on respective backgrounds.
    static let success = Color(light: Color(hex: "#2D8A4E"), dark: Color(hex: "#48C78E"))  // habit complete
    static let warning = Color(light: Color(hex: "#C68400"), dark: Color(hex: "#E8A317"))  // streak needs attention
    static let error = Color(light: Color(hex: "#CC2936"), dark: Color(hex: "#FF6B6B"))    // action incomplete — needs retry
    static let info = Color(light: Color(hex: "#1976D2"), dark: Color(hex: "#64B5F6"))     // informational
    static let accent = Color.accentColor                            // primary CTA, selected state

    // Specific UI elements — all adaptive
    static let streakFire = Color(light: Color(hex: "#E8590C"), dark: Color(hex: "#FB923C"))  // streak fire — explicit brand orange, not system .orange
    static let moodSelected = Color.accentColor                      // ring around selected emoji
    static let cardShadow = Color(light: Color.black.opacity(0.08), dark: Color.black.opacity(0.24))  // stronger in dark mode for depth
    static let premiumGold = Color(light: Color(hex: "#B8860B"), dark: Color(hex: "#FFE44D"))  // premium badge/accent — light mode darkened from #FFD700 to #B8860B (DarkGoldenrod) for WCAG AA 4.5:1 on white backgrounds
    static let disabled = Color(.systemGray3)                      // disabled controls
    static let disabledText = Color(.systemGray)                   // disabled text

    // Pressed/Active States
    static let pressedOpacity: CGFloat = 0.7                           // opacity during press
    static let pressedScale: CGFloat = 0.97                            // subtle shrink on press
    // Usage: .opacity(isPressed ? DailyArcTokens.pressedOpacity : 1.0)
    //        .scaleEffect(isPressed ? DailyArcTokens.pressedScale : 1.0)
    //        .animation(.easeInOut(duration: 0.1), value: isPressed)

    // Focus State (keyboard/VoiceOver navigation)
    static let focusRingColor = Color.accentColor                      // accent color focus ring
    static let focusRingWidth: CGFloat = 2                             // 2pt stroke
    static let focusRingOffset: CGFloat = 2                            // 2pt offset from component edge

    // Opacity scale (referenced by elevation system)
    static let opacitySubtle: CGFloat = 0.08
    static let opacityLight: CGFloat = 0.12
    static let opacityMedium: CGFloat = 0.16
    static let opacityHeavy: CGFloat = 0.24

    // Border widths
    static let borderThin: CGFloat = 1
    static let borderMedium: CGFloat = 2
    static let borderThick: CGFloat = 4    // Used for mood selection ring

    // Corner radii (referenced by Component Specs table)
    static let cornerRadiusSmall: CGFloat = 10   // Text fields
    static let cornerRadiusMedium: CGFloat = 12  // Habit rows, primary buttons, warning cards
    static let cornerRadiusLarge: CGFloat = 16   // Cards
    static let cornerRadiusCapsule: CGFloat = 20 // Tag chips (use .capsule for toasts/pills)
}
```

**Typography Scale (system Dynamic Type — do NOT use fixed sizes in production):**
| Token | Usage | Design-time size | SwiftUI style |
|-------|-------|-----------------|---------------|
| displayLarge | Streak number on widget | 42pt bold | `@ScaledMetric(relativeTo: .largeTitle) var displayLargeSize: CGFloat = 42` then `.font(.system(size: displayLargeSize, weight: .bold))` — MUST scale with Dynamic Type |
| titleLarge | Screen titles | 28pt bold | `.font(.title)` |
| titleMedium | Section headers | 22pt semibold | `.font(.title2)` |
| titleSmall | Card titles | 18pt semibold | `.font(.title3)` |
| bodyLarge | Primary body text | 17pt regular | `.font(.body)` |
| bodySmall | Secondary text, hints | 15pt regular | `.font(.subheadline)` |
| callout | Form labels, picker text | 16pt regular | `.font(.callout)` |
| caption | Timestamps, fine print | 13pt regular | `.font(.caption)` |
| caption2 | Badge counts, tiny labels | 11pt regular | `.font(.caption2)` |
| footnote | Legal, disclaimers | 13pt regular | `.font(.footnote)` |

**Line-height & Letter-spacing Tokens (reference values — SwiftUI manages actual rendering):**
| Token | Line height ratio | Letter spacing | Notes |
|-------|------------------|----------------|-------|
| displayLarge | 1.1 | -0.5pt | Tight for hero numbers, `.leading(.tight)` |
| displayMedium | 1.1 | -0.5pt | Tight for titles, `.leading(.tight)` |
| displaySmall | 1.15 | -0.3pt | Slightly looser, `.leading(.tight)` |
| titleLarge-titleSmall | 1.2 | 0pt | System default via semantic fonts |
| bodyLarge-bodySmall | 1.4 | 0pt | System default — optimal for readability |
| caption-footnote | 1.3 | 0pt | System default |
SwiftUI semantic fonts (`.body`, `.title`, etc.) use Apple's built-in line heights which match these ratios. The `displayX` styles use explicit `.leading(.tight)` to override. No manual letter-spacing is needed — SF Pro's built-in tracking is designed for these sizes.

    // Extended display sizes (used in specific contexts)
    // displaySmall: 36pt Bold — onboarding title "DailyArc"
    // displayMedium: 32pt Bold — paywall price text
    // IMPORTANT: All display sizes MUST use @ScaledMetric to honor Dynamic Type accessibility settings.
    // Example: @ScaledMetric(relativeTo: .largeTitle) var displaySmallSize: CGFloat = 36
    // Never use fixed .font(.system(size:)) without @ScaledMetric — it violates the "All text MUST use Dynamic Type" rule below.

**Swift implementation — `DailyArcTypography` ViewModifier (uses Dynamic Type natively):**
```swift
struct DailyArcTypography: ViewModifier {
    enum Style {
        case displayLarge, displayMedium, displaySmall
        case titleLarge, titleMedium, titleSmall
        case bodyLarge, bodySmall
        case callout, caption, caption2, footnote
    }

    let style: Style

    /// @ScaledMetric properties for display sizes — these scale with Dynamic Type
    /// while providing visual differentiation between display tiers.
    /// Each must be declared on a View or ViewModifier (not inside a function body).
    @ScaledMetric(relativeTo: .largeTitle) private var displayLargeSize: CGFloat = 42
    @ScaledMetric(relativeTo: .largeTitle) private var displayMediumSize: CGFloat = 36
    @ScaledMetric(relativeTo: .largeTitle) private var displaySmallSize: CGFloat = 32

    func body(content: Content) -> some View {
        switch style {
        case .displayLarge:  content.font(.system(size: displayLargeSize, weight: .bold).leading(.tight))
        case .displayMedium: content.font(.system(size: displayMediumSize, weight: .bold).leading(.tight))
        case .displaySmall:  content.font(.system(size: displaySmallSize, weight: .bold).leading(.tight))
        case .titleLarge:    content.font(.title)
        case .titleMedium:   content.font(.title2.weight(.semibold))
        case .titleSmall:    content.font(.title3.weight(.semibold))
        case .bodyLarge:     content.font(.body)
        case .bodySmall:     content.font(.subheadline)
        case .callout:       content.font(.callout)
        case .caption:       content.font(.caption)
        case .caption2:      content.font(.caption2)
        case .footnote:      content.font(.footnote)
        }
    }
}
// Usage: Text("Title").modifier(DailyArcTypography(style: .titleLarge))
// Display sizes use @ScaledMetric for Dynamic Type scaling with visual differentiation:
// displayLarge (42pt base) — hero stats, milestone numbers
// displayMedium (36pt base) — onboarding title "DailyArc"
// displaySmall (32pt base) — paywall price text
// All other cases use semantic SwiftUI font styles — Dynamic Type scales automatically.
// The design-time sizes in the table above are references only — runtime adapts to user settings.
```

All text MUST use Dynamic Type via SwiftUI semantic font styles. Custom sizes are design-time references only — runtime sizes adapt to user accessibility settings.

**Spacing Scale (multiples of 4pt base unit):**
| Token | Value | Usage |
|-------|-------|-------|
| spacing.xs | 4pt | Between icon and label, inline padding |
| spacing.sm | 8pt | Between related elements, list item internal |
| spacing.md | 12pt | Card internal padding |
| spacing.lg | 16pt | Section padding, card margins |
| spacing.xl | 24pt | Between sections |
| spacing.xxl | 32pt | Screen top/bottom padding |
| spacing.xxxl | 48pt | Between major page sections |
| spacing.jumbo | 64pt | Onboarding/paywall hero spacing |

```swift
/// Swift implementation — use these instead of magic numbers
enum DailyArcSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    static let jumbo: CGFloat = 64
}
```

**Device Layout Breakpoints:**
| Device class | Width | Adaptations |
|-------------|-------|-------------|
| SE / compact (375pt) | 375pt | Per-habit card grid → single column, heat map cell 10pt (not 12pt), onboarding value props collapse at AX3+, spacing.xl → spacing.lg |
| Standard (390-393pt) | 390-393pt | Default layout — all specs as written |
| Large (414-430pt) | 414-430pt | Per-habit card grid 2 columns with wider cards, heat map cell 14pt for better tap targets |

Use `@Environment(\.horizontalSizeClass)` and `GeometryReader` width checks.

**Supported device classes (v1.0):** iPhone only, portrait only. Enforce via Info.plist `UISupportedInterfaceOrientations = [UIInterfaceOrientationPortrait]`. iPad is deferred to v1.1 (see Deferred section). If `horizontalSizeClass == .regular` is detected (e.g., iPad multitasking fallback), apply rule 19b: constrain to 500pt max-width, centered (NOT 390pt — rule 19b is authoritative for iPad layout).

**Responsive layout rules (authoritative — apply to all screens):**
- **iPhone SE (375pt width):** Per-habit card grid uses single column. Heat map cell size reduces to 10pt. Onboarding value props collapse to single tagline at AX3+. Spacing tokens demote one level (`xl` → `lg`, `lg` → `md`). Mood emoji circles reduce to 52pt diameter (still ≥44pt min tap target).
- **Standard iPhone (390-393pt):** Default layout — all specs as written. This is the design reference width.
- **Large iPhone (414-430pt):** Per-habit card grid uses 2 columns with wider cards (180pt each). Heat map cell 14pt for better tap targets. Celebration confetti spread increases proportionally.
- **Dynamic Type scaling:** At AX3 and above, switch per-habit cards to single column regardless of device width. At AX5, collapse Today View sections into expandable accordions (mood, habits, streak recovery) to prevent excessive scrolling. All touch targets remain ≥44pt at all Dynamic Type sizes.

**Component Specs:**
| Component | Corner radius | Min touch target | Shadow |
|-----------|--------------|-----------------|--------|
| Primary button | 12pt | 50pt height, full width | none |
| Card | 16pt | n/a | 0 2 8 cardShadow |
| Habit row | 12pt | 44pt min height | none |
| Emoji circle | 50% (circular) | 60pt × 60pt | none |
| Tag chip | 20pt (capsule) | 44pt height | none |
| Color swatch | 50% (circular) | 44pt × 44pt | none |
| Text field | 10pt | 44pt min height | none |
| Badge ceremony (Milestone) | 20pt | n/a | 0 4 16 cardShadow |
| Badge ceremony (Summit/Zenith) | 24pt | n/a | 0 8 24 cardShadow |
| Celebration overlay | 0pt (full-screen) | n/a | none |

**Pressed State Mapping (per-component):**
| Component | Pressed effect | Notes |
|-----------|---------------|-------|
| Primary button | opacity 0.7 + scale 0.97 | Both effects combined |
| Habit row (tap to complete) | opacity 0.7 | Scale omitted — row width makes scale look odd |
| Emoji circle (mood/energy) | scale 0.95 | No opacity — visual selection ring provides feedback |
| Tab bar item | opacity 0.7 | System default behavior |
| Tag chip | opacity 0.8 | Slightly subtler than buttons |
| Navigation arrow | opacity 0.7 | Quick position feedback |
| Card (tappable) | scale 0.98 | Subtle, card-appropriate |
| "+" habit button | scale 0.95 + opacity 0.7 | Prominent call-to-action |

**Activity tag chip visual spec (Today View):**
- Unselected: `backgroundSecondary` fill, `textPrimary` text, no border
- Selected: accent color fill at 15% opacity, accent color text, accent border (1pt)
- Emoji: 16pt, left-aligned within chip, 4pt gap to label text
- Horizontal padding: 12pt. Vertical centering within 44pt height.
- Inter-chip spacing: 8pt (`DailyArcSpacing.sm`)
- "+" chip: dashed border (1pt, `textTertiary`), "Add" label. Tap opens inline text field replacing the chip, 20-char limit, no emoji restriction. On save: auto-selects new tag, scrolls to show it.
- Max custom tags: 10 (prevents unbounded horizontal scroll). After 10: "+" chip disabled with tooltip "Maximum tags reached."

**CompletionCircle Spec:**
- Card size: 40pt diameter, 3pt stroke width
- Detail view size: 60pt diameter, 4pt stroke width
- Track color: `Color(.systemGray5)`
- Fill color: habit color from palette (via `colorIndex`)
- Center text: completion percentage, `caption` weight bold
- Fill animation: `.easeInOut`, 0.6s, animated `trim(from:to:)`

**All interactive elements MUST be ≥44pt × 44pt** per Apple HIG accessibility guidelines.

**Elevation / Z-Index System:**
| Level | Usage | Shadow | zIndex |
|-------|-------|--------|--------|
| 0 (base) | Background, content | none | 0 |
| 1 (card) | Habit cards, stat cards | 0 2 8 cardShadow | 1 |
| 2 (floating) | FAB, streak badge overlay | 0 4 12 black.opacity(0.12) | 10 |
| 3 (overlay) | Undo toast, celebration | 0 8 24 black.opacity(0.16) | 100 |
| 4 (modal) | Sheets, paywall, alerts | system-managed | 1000 |

**Toast/Snackbar Component Spec:**
- Height: 48pt, corner radius: 24pt (capsule shape)
- Background: `backgroundTertiary` with `opacity.medium` blur
- Text: `bodySmall`, single line, centered
- Action button (e.g., "Undo"): `bodySmall` bold, accent color, right-aligned
- Position: bottom safe area + `spacing.lg` (16pt) from bottom
- Auto-dismiss: 3 seconds (extended to 6 seconds when `AccessibilityEnvironment.isVoiceOverRunning` — gives VoiceOver users time to discover and activate the Undo button). Auto-dismiss pauses entirely while VoiceOver focus is on the toast. When VoiceOver is active, add an explicit "Dismiss" button (`.accessibilityAddTraits(.isButton)`) alongside Undo.
- Dismiss gesture: swipe down
- Entrance: slide up from bottom, `.easeInOut`, 0.3s
- Exit: fade out, `.easeInOut`, 0.2s
- Elevation: level 3 (overlay)
- Max width: screen width - 2 × `spacing.lg` (32pt total horizontal margin)

**Animation Defaults:**
| Animation | Curve | Duration | Notes |
|-----------|-------|----------|-------|
| Habit completion checkmark | `.spring(response: 0.35, dampingFraction: 0.6)` | ~0.35s | Bouncy pop |
| Confetti burst | linear | 2.0s | Canvas-based, 50 particles |
| Streak number change | `.spring(response: 0.3, dampingFraction: 0.8)` | ~0.3s | Number rolls up |
| Card appear | `.easeOut` | 0.25s | Fade + slight scale(0.95→1.0) |
| Tab switch | `.default` | system | Use SwiftUI default |
| Mood emoji selection | `.spring(response: 0.2, dampingFraction: 0.7)` | ~0.2s | Scale pulse 1.0→1.15→1.0 |
| Undo toast | `.easeInOut` | 0.3s appear, 0.2s dismiss | Slide up from bottom |
| Milestone badge | `.spring(response: 0.5, dampingFraction: 0.5)` | ~0.5s | Bouncy scale + rotation |
| Progress ring fill | `.easeInOut` | 0.6s | Animated trim |
| Sheet presentation | `.spring(response: 0.35, dampingFraction: 0.86)` | ~0.35s | System-like spring |
| Date navigation swap | `.easeInOut` | 0.2s | Fade content (opacity 1→0→1) on date change |
| NavigationLink push/pop | system default | system | Do NOT override — SwiftUI's native push/pop with swipe-back |
| Comeback Arc reconnection | `.easeInOut` | 1.5s | Broken arc gap fills with golden glow, segments merge |
| 365-day full circle | `.easeInOut` | 1.5s | Arc draws 0°→360° in `premiumGold`, 6pt line width |
| Sheet queued swap | `.easeOut` | 0.3s | Current sheet dismisses fully before next presents (no crossfade) |

**All animations respect `AccessibilityEnvironment.isReduceMotionEnabled`.** When enabled: instant state changes, no springs, no confetti, static badges.

**Haptic Feedback Map (authoritative — all interaction points):**
| Interaction | Haptic Type | Notes |
|------------|-------------|-------|
| Habit tap (incomplete → progressing) | `.light` impact | Light tap for increment |
| Habit reaches targetCount | `.success` notification | Achievement feel (3 quick taps) |
| All habits complete for day | `.success` notification | Same as individual, but confetti amplifies |
| Mood emoji selected | `.selection` feedback | Subtle, intimate moment |
| Energy slider changed | `.selection` feedback | Consistent with mood |
| Activity tag toggled | `.light` impact | Quick acknowledgment |
| Streak milestone reached | `.success` notification | Paired with chime sound |
| Badge unlocked | `.success` notification | Paired with milestone chime |
| Streak recovery "Restore" tap | `.success` notification | Relief + achievement |
| First-ever habit completion | `.success` notification | Special moment |
| First-ever mood log | `.success` notification | Self-reflection acknowledged |
| Undo toast tap | `.light` impact | Confirmation of reversal |
| Streak loss displayed | `.light` impact | Gentle, not alarming (see Streak Loss Compassion section — `.light` not `.warning`) |
| Delete confirmation | `.warning` notification | Destructive action gravity |
| Onboarding template selected | `.selection` feedback | Quick, non-intrusive |
| "Start Tracking" button (onboarding) | `.success` notification | Send-off celebration |
| Share card generated | `.light` impact | Confirmation |

| Date navigation arrow tap | `.light` impact | Quick position acknowledgment |
| Calendar picker date selection | `.selection` feedback | Date confirmed |
| Export complete | `.success` notification | Task finished |
| Error retry tap | `.light` impact | Action acknowledged |
| Paywall "Unlock" tap | `.medium` impact | Significant action |
| Badge collection tap (replay) | `.light` impact | Non-primary interaction |

All haptics respect `AccessibilityEnvironment.isReduceMotionEnabled` — when enabled, haptics still fire (they are not visual motion).

**Sound Design (4 custom sounds, optional — respect device mute switch):**
**Priority: P2 — the app can ship silent with haptics only in v1.0.** Sound design is polish, not core functionality. Defer custom audio production to v1.0.1+ unless sounds are already available. Use system sounds as placeholder if needed. The detailed production specs below are reference for an audio designer when resources allow.
| Sound | Trigger | Duration | Character |
|-------|---------|----------|-----------|
| Completion pop | Single habit reaches targetCount | ~0.15s | Soft bubble pop (AudioServicesPlaySystemSound) |
| Milestone chime | Streak milestone reached (7/30/100/365) | ~0.5s | Ascending two-note chime |
| All-complete fanfare | All habits done for the day | ~1.0s | Short celebratory flourish |
| Streak loss settle | First view after streak breaks | ~0.3s | Brief descending half-step — gentle exhale |

Sounds play via `AudioServicesPlaySystemSound` (respects silent mode switch automatically) or `AVAudioPlayer` with `.ambient` category (also respects silent mode — `.ambient` is the correct category for optional sound effects). No explicit mute check needed. Store sounds as .caf files in bundle.

**Sound Design Personality:** The sonic palette is organic and warm, never synthetic or gamified. Each sound should feel like gentle encouragement from a supportive companion:
- **Completion pop:** feels like a soft affirmation — "yes, that counted." Warm, rounded, no sharp attack. Think of a soap bubble popping, not a button click.
- **Milestone chime:** feels like a small celebration between friends — ascending notes suggest growth (arc rising). Musical, not mechanical.
- **All-complete fanfare:** feels like a genuine moment of pride, not a game achievement. Brief brass-like warmth, not 8-bit victory music.
- **Streak loss settle:** feels like a gentle exhale — acknowledging without judging. Brief descending half-step, <0.3s, almost subliminal.
A user should be able to distinguish "that's a habit tap" from "that's a badge" from "that's all done" by sound alone. The sounds collectively reinforce the arc-of-growth metaphor through ascending tonal movement.

**Sound personality audit checklist (pre-launch):** Play all 4 sounds back-to-back with eyes closed. Can you identify each without visual context? If any two sound similar, adjust timbre/duration until each is instantly recognizable. The sounds are a family (same key center, same timbral palette) but each member has a distinct personality — like siblings, not twins.

**Custom notification sound:** Specify a brief custom notification sound (0.3s) using the same C major pentatonic palette and marimba timbre — a single C5 note, marimba-like, -14dB, 0.1s reverb. Exported as .caf in bundle, referenced in `UNNotificationSound(named:)`. This extends the sonic brand to the lock screen.

**Sonic brand guidelines (unifying motif):**
- **Key center:** All sounds rooted in C major pentatonic (C-D-E-G-A). This creates a warm, universally pleasant palette with no dissonance.
- **Arc interval:** Ascending sounds use major 3rd (C→E) or perfect 5th (C→G) — intervals that feel like rising/growth. The descending settle uses minor 2nd (E→D#) — gentle, not tragic.
- **Timbre:** Marimba-like attack with soft sustain. Warm wood/organic character, never metallic or synthetic.
- **Variation (prevents sonic fatigue):** Completion pop pitch shifts subtly per consecutive tap within a session: first tap = C5, second = D5, third = E5, etc. up the pentatonic scale. Resets on session change. This creates an ascending "melody" as the user completes habits, reinforcing the arc metaphor sonically.

**Production specs (for audio designer / sound synthesis):**
| Sound | Fundamental | Waveform | Attack | Decay | Sustain | Release | Peak dB | Notes |
|-------|------------|----------|--------|-------|---------|---------|---------|-------|
| Completion pop | C5 (523Hz) base, shifts up pentatonic | Sine + soft harmonics | 5ms | 80ms | 0% | 50ms | -12dB | Low-pass filter at 4kHz, slight reverb (0.1s room) |
| Milestone chime | C5→E5 (major 3rd) | Marimba-like (sine + 2nd/3rd partial) | 10ms | 200ms | 20% | 150ms | -8dB | Two notes, 200ms apart, 0.2s reverb tail |
| All-complete fanfare | C4→E4→G4 (triad) | Warm brass-like (saw + LP filter) | 15ms | 300ms | 30% | 200ms | -6dB | Three ascending notes, 150ms apart, 0.3s reverb |
| Streak loss settle | E4→D#4 (minor 2nd) | Sine, very soft | 20ms | 150ms | 0% | 100ms | -18dB | Single descending half-step, almost subliminal |
All sounds exported as .caf (Core Audio Format), 44.1kHz, 16-bit. Total bundle size: <100KB for all 4 sounds.

**Skeleton Loading Spec:**
- Base color: `Color(.systemGray5)` (adapts to dark mode)
- Highlight color: `Color(.systemGray4)`
- Animation: shimmer gradient sweep, `linear`, 1.5s duration, repeating
- Corner radius: matches parent component (12pt for cards, 8pt for text lines)
- Skeleton shapes: rounded rectangles matching content layout (title line 40% width, body lines 80-100% width, circles for avatars/emojis)
- Respects reduce motion: when enabled, show static gray placeholders without shimmer
- **Per-screen skeleton blueprints:**
  - *Today View:* Date bar (full width, 16pt height) + 3 habit row placeholders (emoji circle 40pt + name line 50% width + streak badge 60pt) + mood section (5 circles 60pt each in HStack)
  - *Stats View:* Heat map grid (42 cells, 12×12pt each) + trend chart area (full width, 200pt height) + 2 insight card placeholders (full width, 80pt height each)
  - *Settings View:* no skeleton needed (static content, instant render)
  - *BadgesView:* 3×2 grid of badge silhouette circles (64pt each, `systemGray5`) + title line placeholders (50% width) below each circle
  - *PerHabitDetailView:* Header emoji circle (40pt) + name line (60% width) + 2 stat panel placeholders (full width, 60pt height) + bar chart area (full width, 150pt height)
  - *Widget:* `.redacted(reason: .placeholder)` — SwiftUI handles automatically

---

## Project Structure

```
DailyArc/
├── DailyArcApp.swift                  # App entry, ModelContainer, scene phase handling
├── ContentView.swift                  # Tab navigation + onboarding gate
├── Schema/
│   └── DailyArcSchemaV1.swift         # VersionedSchema with all models
├── Models/
│   ├── Habit.swift                    # Habit model (colorIndex Int, cached streaks)
│   ├── HabitLog.swift                 # Completion log (@Relationship to Habit, indexed date)
│   ├── MoodEntry.swift                # Mood + energy + activities (indexed date)
│   └── DaySnapshot.swift              # Computed struct (NOT @Model)
├── ViewModels/
│   ├── TodayViewModel.swift           # Today tab logic (receives @Query data from View)
│   ├── StatsViewModel.swift           # Stats + Insights logic
│   ├── HabitFormViewModel.swift       # Add/Edit habit logic
│   └── SettingsViewModel.swift        # Settings & IAP
├── Views/
│   ├── Today/
│   │   ├── TodayView.swift            # Main dashboard (@Query lives HERE)
│   │   ├── DateNavigationBar.swift    # Date picker for historical day navigation
│   │   ├── MoodCheckInView.swift      # 5 emoji mood selector (independent of habits)
│   │   ├── EnergyPickerView.swift     # 1-5 energy tappable circles (matching mood picker pattern)
│   │   ├── ActivityTagView.swift      # Activity tag selection chips
│   │   ├── HabitListView.swift        # Today's habit list (auto-save on tap)
│   │   ├── HabitRowView.swift         # Single habit row with stepper
│   │   ├── StreakRecoveryBanner.swift  # "1 day gap — tap to continue your arc" banner
│   │   └── CelebrationOverlay.swift   # Full-screen confetti on all-complete
│   ├── Habits/
│   │   ├── HabitFormView.swift        # Add/Edit habit form (shared, template-based)
│   │   ├── HabitManagementView.swift  # Reorder, archive/unarchive, bulk actions
│   │   ├── HabitTemplatesView.swift   # One-tap template habits for onboarding
│   │   └── EmojiPickerView.swift      # Emoji selector grid
│   ├── Stats/
│   │   ├── StatsView.swift            # Statistics + Insights hub (merged)
│   │   ├── HeatMapCanvasView.swift    # Canvas-rendered heat map (Sky-to-Indigo brand gradient)
│   │   ├── MoodTrendView.swift        # LineMark mood chart
│   │   ├── PerHabitCardView.swift     # Habit stat card (streak, rate, sparkline)
│   │   ├── PerHabitDetailView.swift   # Drill-down habit analysis
│   │   ├── CorrelationCardView.swift  # Mood-habit correlation (PREMIUM)
│   │   ├── SuggestionCardView.swift   # RuleEngine suggestions
│   │   └── BadgesView.swift             # Badge collection grid (earned + locked)
│   ├── Settings/
│   │   ├── SettingsView.swift         # Settings hub
│   │   ├── NotificationSettingsView.swift # Reminder management
│   │   ├── DataManagementView.swift   # Export/import
│   │   ├── PrivacySettingsView.swift  # HealthKit, data consent, privacy policy
│   │   ├── PaywallView.swift          # Premium purchase screen
│   │   └── PaywallStubView.swift      # Compile-time stub for early build steps
│   ├── Onboarding/
│   │   ├── OnboardingView.swift       # 3-page onboarding (reduced from 4)
│   │   ├── WelcomePage.swift          # Value prop page
│   │   ├── HabitTemplatePage.swift    # Pick 1-3 starter habits from templates
│   │   └── FirstLogPage.swift         # First mood + habit log preview
│   └── Shared/
│       ├── StreakBadgeView.swift       # 🔥 number display
│       ├── CompletionCircleView.swift  # Circular progress indicator
│       ├── EmptyStateView.swift        # Reusable empty state component
│       ├── LoadingStateView.swift      # Reusable loading spinner
│       └── ErrorStateView.swift        # Reusable error with retry
├── Services/
│   ├── PersistenceController.swift    # SwiftData container + VersionedSchema setup
│   ├── HealthKitService.swift         # @ModelActor HealthKit integration (per-type queries)
│   ├── StreakEngine.swift             # Core streak calculation + cache invalidation
│   ├── RuleEngine.swift               # On-device rule engine (12+ rules) — ONLY copy, not in Models/
│   ├── CorrelationEngine.swift        # Async Pearson correlation with div-by-zero guards
│   ├── StoreKitManager.swift          # IAP management (StoreKit 2)
│   ├── NotificationService.swift      # Local notifications + permission request
│   ├── ExportService.swift            # JSON/CSV export (runs on Task.detached)
│   ├── WidgetDataService.swift        # Widget JSON writer (called from DebouncedSave success path)
│   ├── AnalyticsService.swift         # TelemetryDeck wrapper (DAU, feature adoption, conversion)
│   ├── CrashReportingService.swift    # MetricKit subscriber (crash logs, hangs, disk writes)
│   ├── DedupService.swift             # Periodic duplicate log cleanup (runs once per foreground, <200ms budget).
│   ├── DataCompactionService.swift    # Weekly BGAppRefreshTask: compacts logs >365 days into DailySummary (Build Step 8)
│   └── BackgroundTaskService.swift    # Protocol for UIApplication.beginBackgroundTask abstraction (#if canImport(UIKit))
│                                        # **LogKey definition:** `struct LogKey: Hashable { let habitID: UUID; let date: Date }`
│                                        # Used to group HabitLogs for dedup comparison. Replaces the tuple (UUID, Date) which is not Hashable.
│                                        # Algorithm (canonical — sorted-walk): Fetch HabitLogs from last 30 days sorted by (habitIDDenormalized, date).
│                                        # Walk sorted list; when consecutive entries share the same (habitIDDenormalized, normalizedDate),
│                                        # keep the entry with the highest count and delete the rest. O(N log N) for sort + O(N) for walk.
│                                        # For MoodEntry: same pattern, keep latest `createdAt`.
│                                        # Query scope: last 30 days only (using date index), not full table scan.
│                                        # Batch size: process 500 records per cycle, check `CFAbsoluteTimeGetCurrent()` after each batch.
│                                        # If budget exceeded, bail out and defer remainder to next foreground cycle. Log timeout count to TelemetryDeck.
├── DTOs/
│   ├── HabitDTO.swift                 # Export-safe Codable, Sendable struct (breaks circular @Relationship)
│   ├── HabitLogDTO.swift              # Export-safe Codable, Sendable struct
│   └── MoodEntryDTO.swift             # Export-safe Codable, Sendable struct
├── Widgets/
│   ├── HabitWidgetBundle.swift        # Widget container
│   ├── SmallStreakWidget.swift        # Lock screen widget (FREE) — AppIntentConfiguration
│   ├── MediumTodayWidget.swift        # Home screen today widget (PREMIUM)
│   ├── LargeStatsWidget.swift         # Home screen stats widget (PREMIUM)
│   └── WidgetConfigurationIntent.swift # Minimal AppIntent for widget configuration (required by AppIntentConfiguration):
│                                        # ```swift
│                                        # import WidgetKit
│                                        # import AppIntents
│                                        # struct DailyArcWidgetIntent: WidgetConfigurationIntent {
│                                        #     static var title: LocalizedStringResource = "DailyArc Widget"
│                                        #     static var description = IntentDescription("Shows your habit progress")
│                                        # }
│                                        # ```
├── Tests/
│   ├── StreakEngineTests.swift        # Unit tests for streak calculation
│   ├── RuleEngineTests.swift          # Unit tests for suggestion generation
│   ├── CorrelationEngineTests.swift   # Unit tests for Pearson correlation
│   ├── ExportServiceTests.swift       # Unit tests for export/import round-trip
│   ├── FetchOrCreateTests.swift       # Unit tests for upsert pattern
│   ├── PerformanceTests.swift         # XCTest measure {} regression tests (CorrelationEngine, StreakEngine, heat map, DedupService)
│   └── DebugDataGenerator.swift       # Synthetic data seeder for testing (365 days, milestones)
└── Utilities/
    ├── DateHelpers.swift              # Date normalization, range helpers
    ├── HapticManager.swift            # Haptic feedback
    ├── ColorExtensions.swift          # Color(hex:) -> Color? initializer (parses "#RRGGBB" hex strings). Returns nil for invalid input. Used by Habit.color(for:) and heat map colors. Adaptive light/dark via colorScheme parameter at call site.
    ├── Constants.swift                # Free tier limits, color palette, streak milestones
    └── DebouncedSave.swift            # 300ms debounced context.save() wrapper (see implementation below)
```

---

## Navigation Architecture

**Tab-based root navigation (3 tabs):**
```
TabView (persisted via @AppStorage("selectedTab"))
├── Tab 1: "Today" (house.fill)
│   └── TodayView
│       ├── DateNavigationBar (inline, not NavigationStack)
│       ├── MoodCheckInView (inline section)
│       ├── HabitListView (inline section)
│       │   ├── → HabitFormView (sheet, .add mode)
│       │   └── → HabitFormView (sheet, .edit mode, via swipe)
│       ├── → HabitManagementView (NavigationLink from "Manage")
│       └── → Calendar Picker (sheet, from long-press date label)
├── Tab 2: "Stats" (chart.line.uptrend.xyaxis)
│   └── StatsView
│       ├── Segment: "Your Arc" (default)
│       │   ├── HeatMapCanvasView (inline)
│       │   ├── MoodTrendView (inline)
│       │   ├── Per-Habit Cards (LazyVGrid)
│       │   │   └── → PerHabitDetailView (NavigationLink)
│       │   │       └── → HabitFormView (sheet, .edit mode)
│       │   └── → BadgesView (NavigationLink from header)
│       └── Segment: "Insights" (premium-gated)
│           ├── CorrelationCardView (expandable inline)
│           ├── SuggestionCardView (inline)
│           └── Activity Insights (inline)
└── Tab 3: "Settings" (gear)
    └── SettingsView (Form)
        ├── → NotificationSettingsView (NavigationLink)
        ├── → DataManagementView (NavigationLink)
        ├── → PrivacySettingsView (NavigationLink)
        ├── → PaywallView (sheet)
        └── → SafariView (privacy policy, sheet)
```

**Navigation patterns:**
- **Primary navigation:** TabView with 3 tabs. Each tab wraps content in a `NavigationStack` for drill-down.
- **Modal presentation:** HabitFormView (add/edit), PaywallView, Calendar Picker — use `.sheet` for overlay interactions that return to origin.
- **Drill-down:** PerHabitDetailView, BadgesView, Settings sub-sections — use `NavigationLink` within `NavigationStack`.
- **Deep links:** `dailyarc://today` → Tab 1, `dailyarc://stats` → Tab 2. Handled in `DailyArcApp.onOpenURL`. **Deep link error handling:** Malformed or unsupported deep link paths → silently navigate to Today tab (safe default). Deep links arriving during onboarding (before `hasCompletedOnboarding`) → queue and execute after onboarding completes. `dailyarc://stats` with zero data → navigate to Stats tab which shows its own empty state.
- **Navigation state restoration:** Persist each tab's `NavigationPath` using `@SceneStorage("todayPath")`, `@SceneStorage("statsPath")`, `@SceneStorage("settingsPath")` with `Codable` serialization. On cold launch, restore path if data exists. If the restored destination no longer exists (deleted habit), pop to root gracefully. **Navigation destination types (must be Codable + Hashable):**
```swift
enum TodayRoute: Codable, Hashable {
    case habitDetail(UUID)     // habit.id, NOT PersistentIdentifier
    case habitForm(UUID?)      // nil = add new, UUID = edit existing
}
enum StatsRoute: Codable, Hashable {
    case perHabitDetail(UUID)
    case badgeCollection
}
enum SettingsRoute: Codable, Hashable {
    case privacy, notifications, dataManagement, about
}
```
Use `Habit.id` (UUID) rather than `PersistentIdentifier` as navigation values — UUIDs are stable across app versions while PersistentIdentifier's serialized form is opaque and may change. On restoration, look up the UUID in ModelContext; if not found, pop to root.
- **Swipe-to-go-back:** Preserved for all `NavigationStack` drill-downs. Do NOT add custom gesture recognizers that conflict with the system back swipe.
- **Gesture conflict resolution (Today View):** Habit row swipe-left-to-edit requires a minimum horizontal distance of 20pt before activating, preventing accidental swipe during rapid count tapping. Tap gesture on habit row takes priority over swipe gesture.
- **Gate:** If `!hasCompletedOnboarding`, present `OnboardingView` as full-screen cover (`.fullScreenCover`), dismissing to ContentView on completion.

---

## Screen-by-Screen UI Specification

### Screen 1: Onboarding (3 pages — age gate + consent embedded in page 1 to reduce drop-off)

**IMPORTANT: Pre-onboarding gates collapsed.** Previously: age gate → GDPR consent → 3 onboarding pages = 5 screens before first value. Each screen loses 10-20% of users. Now: age + consent are embedded in onboarding page 1 as lightweight inline elements, reducing the flow to 3 screens total.

**Page 1 — Welcome + Age + Consent (combined):**
**Layout guidance:** This page is content-dense. Wrap in `ScrollView` to prevent clipping on iPhone SE (375×667pt) and at large Dynamic Type sizes. Vertical spacing: 16pt between sections (compact), 24pt between the value props and the age/consent section. The "Get Started" button should use `.safeAreaInset(edge: .bottom)` to remain always visible. At AX5 Dynamic Type, the value prop bullets collapse to a single "See how habits shape your mood" tagline to save space.

**Two-step progressive disclosure (reduces cognitive load — max 3 concepts per visible step):**
1. **Step 1 (visible on load):** App icon, title, tagline ONLY. Three value prop bullets with staggered fade-in. "Continue" button. **Cognitive budget: 3 items** (icon+title, tagline, value props). Zero legal content, zero form fields. This is purely emotional.
2. **Step 2 (after "Continue" tap):** Smooth scroll/transition reveals age picker + consent toggles below, with "Get Started" replacing "Continue". The value props remain visible above (not replaced) so the user maintains context. **Cognitive budget: 3 items** (age picker, consent toggles grouped as one section, privacy policy link).
This splits the page into two cognitive chunks: "What is this app?" → "Quick setup". Users see the emotional hook first, then the legal requirements. The transition uses `.animation(.easeInOut(duration: 0.3))` on the consent section's opacity and offset.
**Fallback for impatient users:** If the user scrolls down before tapping "Continue", the consent section is already in the DOM (just alpha 0) and becomes visible, preventing confusion.
**Onboarding completion rate target:** ≥85% of users who see Page 1 should complete all 3 pages. Track via TelemetryDeck: `onboarding_page_1_shown`, `onboarding_page_2_shown`, `onboarding_page_3_shown`, `onboarding_completed`. If completion rate < 75%, investigate which page has the highest drop-off.

- App icon (120pt) centered
- "DailyArc" title (bold, 36pt)
- Tagline: "Every day adds to your arc." (gray, 18pt) — uses **secondary tagline** per tagline hierarchy (onboarding = emotional throughline, not marketing)
- 3 value prop bullets (SF Symbol + text):
  - "Your daily habits shape an arc of growth"
  - "Discover the connection between what you do and how you feel"
  - "Your arc lives on your device. Only yours."
- **Inline age verification (below value props):** "Date of birth" month+year picker (compact, single row). If age < 13: navigate to COPPA block screen. Store DOB in **Keychain** (survives app reinstall — prevents COPPA bypass) via a `KeychainDOBService` helper. Keys: `"dobMonth"`, `"dobYear"`. Also mirror to `@AppStorage` for fast non-sensitive reads, but Keychain is the source of truth. On launch, check Keychain first for age recalculation. Do NOT store full DOB for privacy — month+year is sufficient for COPPA age check.
  **Keychain error monitoring:** Track all Keychain read/write failures via `keychain_error` TelemetryDeck signal with `operation` (read/write), `key` (dobMonth/dobYear/stableUserID/isCOPPABlocked), and `osstatus` parameters. Target: <1% failure rate across all Keychain operations. If failure rate exceeds 1%, investigate: common causes are device Keychain corruption after iOS update, Keychain access group misconfiguration, or background access when device is locked (use `kSecAttrAccessibleAfterFirstUnlock` for all DailyArc Keychain items). Fallback: if Keychain read fails for DOB, fall back to `@AppStorage` mirror (degraded but functional). If Keychain read fails for `stableUserID`, generate a new one (experiment assignment may change — acceptable trade-off vs blocking the user).
- **Inline consent (below age picker):** Three toggles matching the authoritative GDPR consent flow (see Settings → Health & Privacy for full spec):
  - Toggle: "I consent to on-device data processing" (**required** to proceed)
  - Toggle: "I consent to HealthKit data for habit tracking" (optional, can enable later in Settings)
  - Toggle: "I consent to mood-habit pattern analysis" (optional, **default OFF** per EDPB Art. 9 guidance — see Settings spec for re-prompt behavior)
  - "View Privacy Policy" link → SafariView
  - **Data controller identity (GDPR Art. 13(1)(a)):** Below toggles, in `footnote` style: "Data controller: [Your Legal Name], [Country]. Contact: privacy@dailyarc.app"
  - **Retention criteria (GDPR Art. 13(2)(a)):** In the privacy policy link target AND as tooltip on the required consent toggle: "Your data is stored on your device only and retained until you delete it."
- "Get Started" button (full width, accent color) — disabled until age entered + required consent checked

**Page 2 — Pick Your Habits (Template-Based):**
- Title: "Choose your habits" (bold, 24pt)
- Subtitle: "Pick 1–3 to start. You can always add more later." (Matches free tier limit of 3 habits — avoids showing a paywall immediately after onboarding if user picks 4)
- Grid of 8 one-tap template habits:
  - 🏃 Exercise | 📚 Reading | 🧘 Meditate | 💤 Sleep 8hrs
  - 💧 Drink Water | 📝 Journal | 🚶 Walk | 🎨 Creative Time
- Each template is a rounded rectangle: emoji (40pt) + name. Tap toggles selection (accent border).
- Pre-filled: frequency=daily, targetCount=1, no reminder
- **Implementation intentions (after template selection):** Below the grid, show a quick "When will you do this?" selector per selected habit: "Morning / Afternoon / Evening" segmented control. Sets `reminderTime` to 8AM / 1PM / 8PM respectively and `reminderEnabled = true`. Research (Gollwitzer 1999) shows stating when you'll do a behavior 2-3x improves follow-through. If user skips this step, reminders default to off.
- **Personalization signal:** Above the template grid, show a single "What's your main goal?" picker: "Get healthier / Be more productive / Build mindfulness / Just trying it out." Use this to reorder templates (health-focused users see Exercise first) and to segment TelemetryDeck analytics. Stored in `@AppStorage("userGoal")`.
- User can select 1–3 templates (minimum 1, maximum 3 — matches free tier limit, prevents immediate paywall friction after onboarding)
- Below selection: "Start with up to 3 habits free. Upgrade anytime for unlimited." (subtle, `caption` font, `textTertiary` — sets premium expectation without friction, prevents future paywall feeling like bait-and-switch)
- "Skip" link below for users with niche habits not in templates → goes directly to Page 3 with no habits (they'll add custom ones from Today View)
- "Next" button (enabled when 1+ selected)

**Page 3 — First Check-In Preview + Notification Permission:**
- Title: "Your arc starts here" (bold, 24pt)
- Mock-up of the Today View showing selected habits with completion circles. Below the preview: a sample insight card with mock data — 'On exercise days, mood averages 4.2' — demonstrating the value proposition before the user has real data. Label: 'This is what you'll discover after 2 weeks of logging.'
- 5 emoji mood selector (interactive preview — **tapping here does NOT save data**, it's a demo)
- **Notification opt-in (below preview):** "Get a gentle evening reminder?" toggle (default ON). If toggled ON, request `UNUserNotificationCenter.requestAuthorization` BEFORE transitioning to Today View. This is the optimal moment: user has just seen the value proposition and is primed to say yes. If permission denied, gracefully continue — reminders can be enabled later in Settings.
- **Email collection (below notification toggle, optional):** TextField with placeholder "Your email (optional)" + value proposition copy below: "Get a weekly summary of your arc — tips, stats, and encouragement." `keyboardType(.emailAddress)`, `textContentType(.emailAddress)`, `autocapitalization(.never)`. Stored in `@AppStorage("userEmail")`. **Never required** — purely opt-in. If provided, validate format (contains "@" and "."). **Expected opt-in rate target: 15-25%** (industry benchmark for utility apps). This is the sole email collection surface — Settings also has a link to update/add email.
- **Email marketing consent (required for GDPR/ePrivacy):** Below the email field, show a checkbox (NOT pre-ticked): "I agree to receive weekly summary emails from DailyArc." Store consent separately: `@AppStorage("emailMarketingConsentDate")` (ISO 8601 timestamp). Email is only exported to Buttondown if this consent is given. Settings → Privacy includes "Delete my email" option that clears `@AppStorage("userEmail")` and `emailMarketingConsentDate`.
- "Start Your Arc" button (full width, accent color)
- On tap: creates selected template Habits in SwiftData, stores `@AppStorage("hasCompletedOnboarding") = true`

**Empty state if onboarding skipped:** If user somehow bypasses onboarding, Today View shows an EmptyStateView: "No habits yet. Tap + to create your first one."

Uses `.sheet` presentation with progress dots. Show onboarding only when `hasCompletedOnboarding == false`.

**Re-onboarding and feature discovery:** Settings → Help & Support includes: (a) "Replay Onboarding" button that resets `hasCompletedOnboarding` and re-presents the onboarding flow, (b) "Permissions Guide" explaining how to re-enable denied notifications and HealthKit permissions with a direct "Open Settings" deep link, (c) "What's New" sheet displayed on first launch after each version update, showing new features with brief descriptions — triggered by comparing `@AppStorage("lastSeenVersion")` to `Bundle.main.infoDictionary["CFBundleShortVersionString"]`.

**Email service backend:** Collected emails are stored in `@AppStorage("userEmail")` for v1.0 (no email is actually sent in-app). Email drip sequences described in the marketing section require Buttondown (free tier supports 1,000 subscribers, privacy-friendly, no tracking pixels). Set up Buttondown account as a pre-launch task. **Sign a Data Processing Agreement (DPA) with Buttondown before exporting any emails (GDPR Art. 28 — blocking prerequisite).** Export collected emails to Buttondown via manual CSV upload after reaching 50+ collected emails — **only export emails where `emailMarketingConsentDate` is set.** This is a post-launch operational task, not an in-app integration.

### Screen 2: Today View (Tab 1 — Main Dashboard)

**Today View content density rules (max concurrent inline elements):**
- Maximum **2 contextual banners/cards** visible at once (e.g., streak recovery + milestone card). If more qualify, show the 2 highest-priority and defer the rest to next session.
- Priority order: streak recovery banner > Day N milestone card > quiet middle card (Day 45/60/75/90) > monthly reflection card > returning-after-absence re-engagement card > weekly preview card > insight nudge
- **Deferred banner persistence:** Track deferred banners in `@AppStorage("deferredBanners")` as a JSON-encoded `[String]` of banner type identifiers. On next session start, check deferred list and show top 2 by priority. Clear shown banners from deferred list. Clear entire deferred list on app update (prevents stale banners from old versions).
- **3+ banner collision matrix:** When 3+ banners qualify, apply priority order to select top 2, defer rest to next session. Specific collision rules:
  - Streak recovery + milestone + returning-after-absence: Show streak recovery + milestone (returning greeting replaces the standard greeting text but does NOT consume a banner slot — it IS the greeting, not a separate card)
  - Milestone + insight nudge + weekly preview: Show milestone + insight nudge (weekly preview defers)
  - All 5 qualify simultaneously: Show streak recovery + milestone; defer remaining 3
  - **Rule:** Returning-after-absence greeting is a greeting variant, NOT a banner. It replaces the standard "Good morning" text. Re-engagement cards ARE banners and compete for slots. These are distinct.
- When a transient banner/card is dismissed or expires, content below shifts upward using `.animation(.easeOut(duration: 0.2))` to prevent jarring jump.
- **Scroll position anchoring:** After a celebration overlay dismisses, scroll position returns to where the user was (save scroll offset before overlay, restore after).

**Date Navigation Bar (top):**
- Left arrow "<" / Right arrow ">" to navigate days
- Center: small calendar icon (SF Symbol `calendar`, 14pt, `textTertiary`) beside date label ("Today", "Yesterday", or "Mon, Mar 10") — the icon signals tappability and hints at the calendar picker. **Tap or long-press center label → calendar picker** (`.datePickerStyle(.graphical)`, sheet presentation, max date = today, min date = habit start date or 365 days ago). Allows quick jump to any past date for backfill. Dismiss on date selection. Calendar picker uses accent color for selected date, `backgroundSecondary` for sheet background.
- Right arrow disabled if showing today (can't navigate to future)
- Allows backfilling missed days — user navigates to past date, logs habits and mood
- **Discovery nudge:** If user has never navigated dates, show one-time tooltip on first week: "Missed a day? Tap ← to go back and log it." + "Long-press for calendar" tooltip after 3 days.

**Mood Check-In Section (below date bar):**
- **Independent from habit logging — mood is optional**
- If no mood logged for selected date: show card with "How are you feeling?" prompt
- 5 tappable emoji circles (60pt): 😔 😕 😐 🙂 😄
- **No emoji pre-selected** — all 5 equally sized, no visual bias toward "neutral" (3). This prevents central tendency bias in correlation data. User MUST tap to log mood.
- **Scale methodology note:** The 5-point emoji scale treats ordinal data as pseudo-interval for Pearson correlation. This is a known simplification (see Havlicek & Peterson, 1976). The emoji anchors (sad to happy) impose an emotional frame that may exhibit acquiescence bias (positive skew). Mitigated by: (1) no default selection, (2) confidence qualifiers on small samples, (3) plain-language display that never shows raw coefficients. Consider A/B testing a 7-point scale in v1.1.
- Selected emoji has accent-color ring (4pt stroke) + label below (e.g., "Feeling great!")
- **Auto-saves mood on emoji tap** via `MoodEntry.fetchOrCreate(date:context:calendar:)` — no separate save button. The `calendar:` parameter is required (same pattern as `HabitLog.fetchOrCreate`) for consistent date normalization.
- **Undo toast:** After mood auto-saves, show 3-second toast: "Mood logged ✓ — Undo" with undo action that reverts to previous moodScore (or deletes entry if first log)
- After mood selected, show:
  - Energy picker: 5 tappable circles, labeled 1–5 with 'Low' and 'High' endpoints. Each circle 44pt diameter (intentionally smaller than mood's 60pt — energy is secondary input, visual hierarchy: mood=primary 60pt, energy=secondary 44pt). Tap to select, accent ring (3pt stroke) on selected. Auto-saves on selection.
  - Activity tags: scrollable horizontal chip row with pre-defined activities:
    - 👥 Social | 🏃 Exercise | 💼 Work | 🎨 Creative | 🎵 Music | 📚 Reading | 🧘 Mindful | 😴 Rest
    - Tap to toggle (multi-select). Custom "+" button to add user-defined tags.
    - Auto-saves on toggle
  - Notes field: expandable TextField, "Add a note..." placeholder. Auto-saves on editing end. Keyboard toolbar: "Done" button to dismiss. `.scrollDismissesKeyboard(.interactively)` on parent ScrollView.

**Streak Recovery Banner (conditional):**
- Shows if any habit missed only 1–2 days and recovery is possible
- Yellow card: "1 day gap on 🏃 Exercise — tap to continue your arc."
- "Continue Arc" button applies streak recovery via RuleEngine
- Dismiss "✕" button hides for this session
- **Recovery rules transparency:** When streak recovery is unavailable (gap exceeds 2 days, or user has exhausted their 2-per-30-day rolling allowance), show a disabled-state banner instead of silently hiding: "Recovery unavailable — streaks can be recovered for 1-2 missed days, up to twice per month. Your new arc starts today." This prevents "why can't I recover?" support tickets. The disabled banner uses `backgroundSecondary` with `textTertiary` text and no action button.

**Habit Completion Section (middle):**
- Header: "Habits" with **visual arc progress indicator** (270-degree arc, 28pt diameter, fills proportionally as habits complete — e.g., 3/5 = 162 degrees filled, accent color fill, `systemGray5` track) and "+" button to add new habit. When all habits complete, the arc fills to 270 degrees and briefly glows (accent at 30% opacity, 0.3s pulse) before confetti fires. **No numeric "X/Y" badge** — the arc is the brand element, not a score counter.
- List of habits filtered by selected date's frequency rules, sorted by `sortOrder`
- Each HabitRowView shows:
  - Habit emoji (40pt) + name on left
  - Completion circle (hollow → filled based on count/targetCount)
  - Streak fire badge: "🔥 {currentStreak}" in orange (0 = hidden)
  - For targetCount == 1: **tap row to toggle complete/incomplete** — auto-saves via `HabitLog.fetchOrCreate(habit:date:context:)` + debounced `context.save()` (300ms)
  - For targetCount > 1: stepper with "−" / count display / "+" buttons — auto-saves via fetchOrCreate + debounced save
  - **Undo toast:** After habit auto-saves, show 3-second toast: "{emoji} logged ✓ — Undo" with undo action
  - Swipe left to reveal "Edit" and "Archive" actions
- **When habit reaches targetCount:** inline checkmark animation + haptic `.success` + **completion ring flash** (ring momentarily glows in habit color at 1.5x stroke width for 0.2s, then settles back). For targetCount > 1, each increment shows a subtle progress tick (ring segment appears with a tiny bounce). Respects `AccessibilityEnvironment.isReduceMotionEnabled`.
- **When ALL habits complete for the day:** Canvas-based confetti (50-particle budget, 2-second animation) + haptic `.success`. **If reduce motion enabled:** static banner "All done! ✅" instead.
- **Free tier hint:** When free user has 3 active habits: show subtle "Archive a habit to make room, or upgrade" hint at bottom of list

**Loading state:** Skeleton placeholders while SwiftData query resolves (typically instant).
**Error state:** "We hit a bump in your arc. Give it another tap." with retry action. *(Authoritative error copy is in the Whimsy and Delight → Error States section — always reference that section for canonical strings.)*
**Empty state (no habits):** EmptyStateView — illustration + "No habits yet" + "Create Your First Habit" button.

### Screen 3: Habit Form (Add / Edit — shared sheet)

Presented from "+" button (add mode) or swipe-to-edit / management screen (edit mode).

**Template Quick-Start (Add mode only):**
- Top section: "Start from a template" with horizontal scroll of 8 templates (same as onboarding)
- Tap template → pre-fills emoji, name, frequency=daily, targetCount=1
- "Or create custom" divider below

**Form Fields (2 steps — reduced from 4):**

- **Navigation:** "Cancel" or "✕" dismiss button in sheet toolbar (both steps). Step 2 has "Back" button to return to Step 1. Swipe-to-dismiss on the sheet is also supported.

**Step 1 — Details & Schedule:**
- Emoji picker grid (8 columns × 6 rows of common emojis). Tap to select, accent ring.
- Color picker: 10 preset swatches (from palette). Tap to select, checkmark overlay.
- Name TextField (placeholder "e.g., Exercise", required — "Save" disabled if empty)
- Frequency: SegmentedControl (Daily / Weekdays / Weekends / Custom)
  - If Custom: 7 toggle buttons for Sun–Sat. Display "Selected: Mon, Wed, Fri" sentence.
- Target count stepper (1–10, default 1). Label: "Times per day"
- "Next" button

**Step 2 — Reminders & Health:**
- Reminder toggle. If enabled:
  - DatePicker (.compact, default 9:00 AM)
  - **On first toggle: request notification permission via `UNUserNotificationCenter.requestAuthorization`**
- HealthKit section (subtitle: "Sync with Health?"):
  - Toggle: "Auto-log from Health app"
  - If enabled: metric picker ("Workouts", "Steps >5000", "Sleep >7hrs", "Mindful Minutes")
  - **Request HealthKit authorization when toggle enabled (not on save).** If user denies: revert toggle to OFF, show inline warning: "Health access denied — you can enable it in Settings > Privacy > Health." with "Open Settings" link.
  - Description: "Your {metric} from Health will count toward this habit."
- "Save Habit" button (full width, accent color)

**On save (Add mode):**
- Create Habit in SwiftData with sortOrder = (max existing sortOrder + 1)
- If HealthKit enabled: fetch past 30 days via `HKStatisticsCollectionQuery`, auto-populate HabitLogs with `isAutoLogged = true`
- Register `HKObserverQuery` for ongoing sync
- Recalculate streak cache
- Show toast: "🏃 Exercise created!"
- Dismiss sheet

**On save (Edit mode):**
- Update existing Habit properties
- If frequency changed: recalculate streak cache
- Show toast: "🏃 Exercise updated!"
- Dismiss sheet

**Validation:**
- Name must be non-empty (trim whitespace)
- If frequency == custom, at least 1 day must be selected
- Duplicate name warning (non-blocking)

**AX5 Dynamic Type adaptations (HabitFormView):**
- Emoji picker grid collapses from 8×6 to a **searchable list** with emoji name labels (e.g., "🏃 Runner"). Search field at top.
- Template horizontal scroll (8 templates) switches to **vertical list** with full template names.
- Color picker swatches remain circular but enlarge to 60pt (from 44pt) with larger checkmark overlay.
- Frequency segmented control converts to a **Picker** with `.pickerStyle(.menu)` for better touch target sizing.
- Custom day toggles (Sun–Sat) enlarge to full-width rows with toggle switches instead of small buttons.

**Activity tag "+" cancel affordance:** When tapping "+" to add a custom tag, the inline text field includes a clear "✕" cancel button (trailing, 44pt touch target). Tapping cancel reverts to the "+" chip without creating an empty tag. If the user taps outside the text field, also cancel (dismiss keyboard + revert to "+" chip).

### Screen 4: Habit Management (accessible from Today View header "Manage" link)

- **Reorderable list** of all habits (drag handles, EditMode)
- Each row: emoji + name + streak badge + archive/active status
- Swipe actions: Edit (→ HabitFormView in edit mode), Archive/Unarchive
- **Archive compassion toast:** When archiving, show: "{streak} days of {emoji} {name}. A pause in your arc — it'll be here when you're ready." When unarchiving: "Welcome back, {emoji} {name}! Ready to continue your arc?"
- **"Show Archived" toggle** at bottom — when on, shows grayed-out archived habits with "Unarchive" swipe action
- "Add Habit" button at bottom
- **Free tier guard:** If user has 3 active habits and taps "Add", show PaywallView

### Screen 5: Stats + Insights View (Tab 2 — merged, was separate tabs)

**Segment control at top:** "Your Arc" | "Insights" (premium-gated)

**"Your Arc" segment:**

**Heat Map Calendar (top):**
- Canvas-rendered 52-week grid (Sky-to-Indigo brand gradient, not GitHub green)
- Each cell = 1 day, colored by completion % (adaptive for dark mode):
  - No data: `Color(.systemGray6)` (adapts automatically)
  - 0% (logged but nothing done): `Color(.systemGray5)` (adapts)
  - 1–25%: light sky — light: `#B3D9F2`, dark: `#2A5F8A` (brand Sky gradient start, WCAG AA 3:1 on both backgrounds)
  - 26–75%: medium blue — light: `#6BA3D6`, dark: `#3D7AB8`
  - 76–100%: deep indigo — light: `#3A5BA0`, dark: `#7B9FE0` (brand Indigo gradient end, brighter on dark bg for contrast)
**WCAG note:** Dark mode lightest sky `#2A5F8A` provides ~3.2:1 contrast against pure black, meeting WCAG AA 3:1 minimum for non-text elements.
**Contrast Ratio Verification Table (key pairings):**
| Pairing | Light mode ratio | Dark mode ratio | Status |
|---------|-----------------|-----------------|--------|
| textPrimary on backgroundPrimary | 21:1 | 21:1 | Pass |
| textSecondary on backgroundPrimary | 7.2:1 | 7.5:1 | Pass |
| textTertiary on backgroundPrimary | 4.6:1 | 4.8:1 | Pass (AA) |
| accent (Sky) on backgroundPrimary | 4.6:1 | 5.1:1 | Pass (AA) |
| error (Coral) on backgroundPrimary | 4.5:1 | 4.7:1 | Pass (AA) |
| premiumGold on backgroundPrimary | 4.8:1 | 5.2:1 | Pass (AA) |
| premiumGold on backgroundSecondary | 4.2:1 | 4.5:1 | Pass (AA) |
| warning (#C68400) on backgroundPrimary | 4.5:1 | n/a (dark uses #D4A017: 5.1:1) | Pass (AA) |
| textTertiary 30% opacity (tag border) | 3.1:1 | 3.2:1 | Pass (non-text 3:1) |
| heat map lightest sky on black | n/a | 3.2:1 | Pass (non-text, +1pt border) | Additionally, add a 1pt border using `borderThin` token for extra distinguishability. The fixed detail bar below the heat map provides text-based data as accessible fallback.
**Colorblind accessibility:** When `AccessibilityEnvironment.isDifferentiateWithoutColorEnabled` (captured from `@Environment(\.accessibilityDifferentiateWithoutColor)` — add to AccessibilityEnvironment helper per rule 39b) is true, overlay pattern encodings on each cell to ensure the heat map is independently interpretable without color: no data = empty cell, 0% = single centered dot (2pt), 1-25% = single diagonal line, 26-75% = crosshatch pattern, 76-100% = solid fill. Patterns use `textPrimary` at 40% opacity. This satisfies WCAG 1.4.1 (color is not the sole means of conveying information). The fixed detail bar remains the primary accessible fallback for VoiceOver users.
- Tap cell → **fixed detail bar below heat map** (NOT tooltip popover — popovers conflict with scroll gestures): shows date, completion %, habits logged, mood emoji (if logged). Bar is always visible, updates on cell tap.
- Horizontal scroll by week, month labels on top. **Cell dimensions:** 12pt × 12pt squares, 3pt gap between cells, total grid height: 7 × (12 + 3) - 3 = 102pt. Total width: 52 × (12 + 3) - 3 = 777pt (scrollable).
- **Batch-computed:** single query for full year, in-memory grouping
- **Performance degradation strategy:** If heat map `Canvas` rendering exceeds 150ms on first load (measured via `ContinuousClock`), automatically reduce to 180-day view and offer "Show full year" as a tap action. This matches the progressive loading pattern used for StatsView. Log `heatmap_degraded` to TelemetryDeck with `device_model` and `render_ms`.
- **Arc metaphor reinforcement:** The heat map IS the user's arc made visible — 365 data points forming the shape of their year. Add a subtle curved baseline at the bottom of the heat map (1pt line, `textTertiary` at 20% opacity) evoking the arc shape. Section header: "Your Arc This Year" (not just "Heat Map"). This makes the brand metaphor tangible.

**Mood Trend Chart (below heat map):**
- Swift Charts LineMark, last 30 days
- X-axis: date labels every 7 days
- Y-axis: mood score 1–5 with emoji labels (😔 through 😄)
- Line color: accent. Optional dashed overlay: energy score in lighter color.
- Tap point → tooltip: date + mood emoji + energy level
- **Empty state (< 3 mood entries):** "Log your mood for 3+ days to see trends" with illustration

**Per-Habit Statistics Cards (LazyVGrid, 2 columns):**
- For each non-archived habit:
  - Habit emoji (40pt) + name
  - Current streak: "🔥 12 days" (large, orange — reads from cached `habit.currentStreak`)
  - Best streak: "Best: 47 days" (smaller, gray — reads from cached `habit.bestStreak`)
  - Completion rate ring: circular progress, center "82%"
  - Sparkline: last 7 days (1pt line)
  - Tap → PerHabitDetailView drill-down
- **Empty state (no habits):** "Create habits to see your stats here"

**Per-Habit Detail View (drill-down):**
- Header: emoji + name + "Edit" button (→ HabitFormView in edit mode)
- Stat panels (stacked, full width):
  - Total completions (lifetime count)
  - Current streak + start date
  - Best streak + date range
  - This month: bar chart (daily completion, 28–31 bars)
  - Last 12 months: bar chart (12 bars, monthly completion %)
- "Archive Habit" button (orange, confirmation alert — NOT delete)
- "Delete Habit" button (red, destructive confirmation: "Delete {Habit Name}? This will permanently delete {N} days of log data." — fetch count via `ModelContext.fetchCount()` before presenting the alert)

**Insights segment (PREMIUM — free users see a teaser card with one sample insight and "See all insights — {product.displayPrice}" button, NOT a blurred version which signals distrust):**

**Mood-Habit Correlation Card:**
- Title: "What affects your mood?"
- **Minimum 14 days of paired data required** (mood + habit logged same day). If insufficient: "Keep logging for {14 - count} more days to unlock mood insights."
- **Day 14 insight teaser (pre-activation):** Before the user reaches 14 days of paired data, show a teaser insight card on the Stats tab: "Your first insight unlocks in {14 - dayCount} days of logging. Here's a preview:" followed by a sample insight card with anonymized example data ("On exercise days, users average mood 4.2 vs 3.1 on skip days"). The teaser uses `backgroundSecondary` with 50% opacity and a subtle lock icon (SF Symbol `lock.fill`, 16pt) overlay. This previews the premium value proposition and motivates continued logging through the critical Day 1-13 window. After Day 14, replace the teaser with real insights. Track `insight_teaser_viewed` and `insight_teaser_tapped` via TelemetryDeck.
- Top 3 correlations using Pearson coefficient:
  - Format: "🏃 Exercise → mood averages 4.2 on exercise days" (plain language, NOT raw coefficient)
  - Subtext: correlation strength label with effect size context: "Strong positive link" (|r| ≥ 0.5) / "Moderate link" (|r| ≥ 0.3) / "Slight link" (|r| ≥ 0.15) / "No clear link" (|r| < 0.15). **Effect size note:** These thresholds are calibrated for behavioral self-report data (not clinical studies) where |r| = 0.15 is practically meaningful. Include a subtle info icon (ⓘ) next to the label; tapping shows a tooltip: "This measures how consistently your habit and mood move together. Even slight links can reveal useful patterns."
  - Color: `DailyArcTokens.success` if positive (coefficient > 0.15), `DailyArcTokens.textSecondary` (gray) if no clear link (abs < 0.15), `DailyArcTokens.error` if negative (coefficient < -0.15). Do NOT use orange/warning for "no clear link" — orange implies caution, gray implies neutrality. **Canonical definition — all correlation card color references in build steps MUST match this.**
- Tap to expand:
  - **For multi-count habits (targetCount > 1):** scatter plot (Swift Charts PointMark) with habit count (X) vs mood (Y)
  - **For binary habits (targetCount == 1):** side-by-side comparison bar chart showing average mood on "completed" days vs "skipped" days. Scatter plots are meaningless with only 2 x-values.
- **Energy score insights (premium):**
  - "Your energy averages {x} on {habit} days" — surfaces the energy data meaningfully so users don't stop providing it
  - "Your highest-energy days: {dayOfWeek}" — day-of-week energy pattern (computed from 14+ days of energy data)
  - "Energy tends to dip after skipping {habit}" — energy-habit correlation (same Pearson method as mood-habit, filtered for energyScore > 0)
  - Energy trend sparkline in per-habit detail view (7-day trailing average, overlaid on mood trend for comparison)
- **Pearson formula:** See `CorrelationEngine.pearsonCorrelation` for the canonical two-pass mean-centered implementation. **Do NOT use the naive single-pass formula** (`n*sumXY - sumX*sumY`) — it suffers from catastrophic cancellation. The production implementation uses mean-centering for numerical stability. Key guards: n >= 14, epsilon 1e-6, clamp to [-1, 1].

**Smart Suggestions Card:**
- 3–5 suggestions generated by RuleEngine (12+ rules):
  1. `streak > 7`: "Your arc is taking shape! 🔥 {streak}-day streak on {habit}. Keep building."
  2. `streak > 30`: "{streak} days of {habit} — this arc tells a story. Keep writing it."
  3. `completion < 50% this month`: "Your {habit} is at {x}% this month — small steps count!"
  4. `mood higher on habit days`: "On {habit} days, your mood averages {avg} — keep it up!"
  5. `mood lower on skip days`: "When you skip {habit}, your mood tends to dip."
  6. `missed 1-2 days`: "1 day gap — tap to continue your {streak}-day arc."
  7. `weekday vs weekend diff`: "You're more consistent on weekdays. Can you keep it up on weekends?"
  8. `best streak beaten`: "A new chapter in your arc — you just passed your previous best of {old} days."
  9. `all habits complete today`: "You showed up for everything today."
  10. `energy high + mood high correlation`: "High energy days = good mood days for you." **MUST filter entries where energyScore == 0 (sentinel for 'not logged') before computing energy averages.**
  11. `energy low + mood low correlation`: "Low energy days tend to match lower mood." **MUST filter energyScore == 0 sentinel — same as rule 10.**
  12. `new habit < 7 days`: "Keep going with {habit} — the first week is the hardest!"
  13. `no mood logged in 3+ days`: "Don't forget to log your mood — it helps spot patterns."
- Free users see rules 1, 3, 6, 9 only. Premium unlocks all 13.

**Activity Insights (PREMIUM):**
- Activities logged on high-mood days (moodScore >= 4)
- Chip grid: "👥 Social: 8x" / "🏃 Exercise: 12x" / "🎨 Creative: 6x"
- Size proportional to frequency. Color-coded by correlation strength.
- **Empty state (no activities tagged):** "Tag activities when logging mood to see what lifts your spirits."

### Screen 6: Settings View (Tab 3 — was Tab 4)

**Profile Section:**
- Display name TextField (`@AppStorage("userName")`)
- Accent color picker: 10 swatches from palette
- **"Show streaks" toggle** (`@AppStorage("showStreaks")`, default ON): When OFF, hides all streak counters, streak-related notifications, and streak milestone celebrations. The app becomes a pure logging tool without streak pressure — aligned with the Calm brand value and Persona 3 ("Simple Streaker" who may paradoxically prefer no streak display). Habit data is still tracked normally; only the streak UI is suppressed. Re-enabling restores accurate streak counts (StreakEngine always computes, toggle only controls display).

**Notifications & Reminders (summary — authoritative copy and variants are in NotificationService, Build Step 6):**
- Master notification toggle
- "Evening reminder" — daily notification at user-set time (default 8 PM) if no habit logged today
  - *(See NotificationService in Build Step 6 for authoritative title/body/rotation variants — do NOT duplicate copy here)*
- "Streak check-in" — morning-after notification (9 AM next day) if yesterday had incomplete habits
  - *(See NotificationService in Build Step 6 for authoritative copy — titles and body variants are defined there only)*
- "Mood reminder" — daily prompt at user-set time (default 9 PM) to log mood
  - *(See NotificationService in Build Step 6 for authoritative copy)*
- **On first toggle of any notification: request `UNUserNotificationCenter.requestAuthorization`**
- If permission denied: show inline warning "Notifications are disabled in Settings" with "Open Settings" link (`UIApplication.openSettingsURLString`)

**Data Management:**
- "Export JSON" button → ShareLink with all Habits + HabitLogs + MoodEntries as formatted JSON (**FREE — GDPR Article 20 right to portability**). Uses DTO structs (HabitDTO, HabitLogDTO, MoodEntryDTO) to break circular @Relationship for Codable. **All DTO structs MUST have explicit `Sendable` conformance** (e.g., `struct HabitDTO: Codable, Sendable { ... }`) since they cross actor boundaries via Task.detached. **Runs on `Task.detached` with progress indicator** — 7,000+ objects through JSONEncoder blocks main thread. **Cancellation:** Store export Task handle; cancel on dismiss. Report progress via `AsyncStream<Double>` (0.0→1.0).
- "Export CSV" button → ShareLink with flat CSV of all logs (**PREMIUM**)
- "Import JSON" button → file picker, merge (skip existing IDs) or overwrite options (**PREMIUM**)
- "Delete All My Data" button (red, confirmation dialog with specific counts: "Delete All My Data? This will erase {N} habits, {M} logs, and {K} mood entries. This cannot be undone." — counts fetched via `ModelContext.fetchCount()`. Type "DELETE" to confirm — GDPR Article 17 Right to Erasure). Suggest exporting data first: "We recommend exporting your data before deleting." with "Export First" secondary button. Wipes all SwiftData stores, `UserDefaults.standard`, **`UserDefaults(suiteName: "group.com.dailyarc.shared")`** (widget data), and resets to first-launch state. Also calls `WidgetCenter.shared.reloadAllTimelines()` to blank widgets.

**Health & Privacy:**
- HealthKit integration status badge (green "Connected" / gray "Not connected")
- "Manage Health Metrics" → list of synced types with toggles
   - **HealthKit consent capture:** When user enables a HealthKit metric toggle in Settings (post-onboarding), present a consent dialog before requesting authorization: "You are enabling health data processing. Your HealthKit data will be used to auto-log habits on this device only. This data is never transmitted off-device. Do you consent?" Store `@AppStorage("healthKitConsentDate")` separately from main GDPR consent. Required because HealthKit data qualifies as "data concerning health" under GDPR Article 9(2)(a).
   - **Mood data GDPR Art. 9 explicit consent:** Mood scores, when combined with habit data, may constitute health data under GDPR Art. 9 (data revealing mental health patterns). During onboarding consent flow, include explicit acknowledgment: "DailyArc will analyze patterns between your habits and mood. This helps identify what affects your wellbeing. All analysis happens on your device." Separate toggle for mood-habit correlation consent (**default OFF** — EDPB requires affirmative action for Art. 9 explicit consent; pre-ticked toggles are not valid). User must actively enable during onboarding or later in Settings → Privacy. If withdrawn, CorrelationEngine skips mood data and only shows habit completion stats. Store `@AppStorage("moodCorrelationConsentDate")`.
- "Privacy Policy" link → SafariView to **actual hosted privacy policy URL** (not example.com)
- **Age verification gate:** Embedded inline in onboarding Page 1: **date-of-birth picker** (month+year, NOT a binary yes/no — too easy to bypass for COPPA). Calculate age from month+year. If under 13: block app with COPPA explanation. **Storage (consolidated, Keychain is sole source of truth):** Store DOB via `KeychainDOBService` (`"dobMonth"`, `"dobYear"` keys). Mirror `@AppStorage("isAgeVerified")` boolean for fast non-sensitive reads. Do NOT store DOB in @AppStorage — Keychain only. On launch, check Keychain first. **Keychain failure handling:** If Keychain write fails (e.g., corporate-managed device restrictions), fall back to @AppStorage only and log a TelemetryDeck signal `"keychain_write_failed"`. If Keychain read fails on launch, re-prompt DOB (do not block the app). **COPPA block screen copy:** "DailyArc is built for users 13 and older. We want to make sure everyone is safe, and that means following important privacy rules. When you turn 13, your arc will be ready." (No emoji — avoids inviting/emotional tone toward legally blocked minors. Also: if user enters age <13, immediately delete the stored DOB values from BOTH Keychain (via `KeychainDOBService.deleteDOB()`) AND @AppStorage to avoid holding a child's personal data without consent (COPPA 16 CFR 312.3(c)). Store `isCOPPABlocked = true` in **both** Keychain (via `KeychainDOBService.setCOPPABlocked(true)`) **and** `@AppStorage("isCOPPABlocked")` (for fast reads). Keychain is the source of truth — survives app reinstall. On subsequent launches, check Keychain first: if `isCOPPABlocked` is true, show the block screen without re-collecting DOB. The block persists across reinstalls (Keychain survives uninstall on iOS), preventing minors from bypassing by reinstalling and entering a false DOB.)
- **GDPR consent collection flow:** Collected inline during onboarding page 1 (not a separate screen). Also accessible from Settings for users who want to review/update consent:
  - "DailyArc processes your habit and mood data on this device only. Your data is retained until you choose to delete it — we have no access to it." (Satisfies GDPR Art. 13(2)(a) retention period disclosure at point of collection, not just in privacy policy.)
  - Toggle: "I consent to on-device data processing" (required to proceed)
  - Toggle: "I consent to HealthKit data being used for habit tracking" (optional, can enable later)
  - Toggle: "I consent to mood-habit pattern analysis" (optional, **default OFF** per EDPB Art. 9 guidance). **This is the mood correlation consent toggle.** If not enabled, CorrelationEngine skips mood data and only shows habit completion stats. **Critical for premium conversion:** surface this toggle prominently with a brief explanation ("Discover how your habits affect your mood") to encourage opt-in without pre-ticking. Also re-prompt once on first Stats tab visit if not yet enabled: "Enable mood insights? DailyArc can show how your habits affect your mood — all analysis stays on your device." with Enable/Not Now buttons. **Single-shot enforcement:** Store `@AppStorage("moodConsentPromptDismissed") = true` when user taps "Not Now" — never show the re-prompt again (EDPB Guidelines 05/2020: repeated prompting undermines freely-given consent).
  - "View Privacy Policy" link
  - "Continue" button (disabled until required consent given)
  - Store consent state: @AppStorage("gdprConsentDate") (ISO 8601 timestamp), @AppStorage("gdprConsentVersion") (privacy policy version, e.g., "2026-03-01"), @AppStorage("gdprConsentScope") (comma-separated: "processing" or "processing,healthkit,analytics"), @AppStorage("gdprConsentTextHash") (SHA256 hash of the consent text presented — if consent text changes between versions, this proves what the user actually consented to, per GDPR Art. 7(1)). This satisfies GDPR Article 7(1) — ability to demonstrate that consent was given, what was consented to, and under which policy version.
- **GDPR consent withdrawal (Article 7(3)) — distinct from Art. 17 erasure:**
  - Settings → Privacy → two separate actions:
    1. **"Withdraw Processing Consent" toggle** (Art. 7(3)): Stops all future data processing (CorrelationEngine, RuleEngine, analytics). Data remains on device but is inert — no new logs, no computations. User can re-consent at any time (shown consent flow again). This is the "soft" withdrawal: reversible, data preserved.
    2. **"Delete All My Data" button** (Art. 17): Irreversible deletion of all user data. Confirm dialog: "This permanently deletes all habits, mood entries, and settings. This cannot be undone." Triggers full deletion cascade (SwiftData store, Keychain, UserDefaults, App Group). Resets to first-launch state.
  - **Why separate:** Art. 7(3) guarantees the right to withdraw consent without penalty — conflating it with deletion forces users to destroy their data just to pause processing, which the EDPB considers a penalty. Art. 17 erasure is a separate right the user may exercise independently.
  - When consent is withdrawn (not deleted): set `@AppStorage("gdprConsentWithdrawn") = true`, clear `gdprConsentDate`. **UI immediately enters read-only mode:** habit tap targets are disabled (`.disabled(true)`), mood emoji picker is hidden, "Add Habit" button is hidden. Banner at top of Today View: "Data processing paused. Re-enable in Settings → Privacy." This prevents data loss — the user cannot create data that would be silently discarded by the performSave() guard. DebouncedSave's guard is a safety net only. CorrelationEngine and RuleEngine check this flag and return empty results.
- **Legal basis per processing activity (GDPR Article 6):**

| Processing Activity | Legal Basis | GDPR Article |
|---------------------|-------------|--------------|
| Habit & mood data storage | Consent | Art. 6(1)(a) |
| HealthKit data processing | Explicit consent (special category) | Art. 9(2)(a) |
| Anonymous analytics (TelemetryDeck) | Consent (opt-in) | Art. 6(1)(a) |
| Crash reporting (MetricKit) | Legitimate interest | Art. 6(1)(f) — Art. 21 objection right: users can disable MetricKit via Settings → Privacy → "Crash Reporting" toggle (default ON). When disabled, unsubscribe from `MXMetricManager`. Note: MetricKit data is anonymized by Apple before delivery; legitimate interest is well-founded (app stability). |
| Age verification (COPPA) | Legal obligation | Art. 6(1)(c) |
| Data export (portability) | Legal obligation | Art. 6(1)(c) / Art. 20 |

- **Data retention policy:** All data is stored locally and persists until the user explicitly deletes it via "Delete All My Data" or uninstalls the app. There is no server-side retention. Upon app deletion, iOS removes all app data including SwiftData stores and UserDefaults. Document in privacy policy: "Your data is retained on your device until you choose to delete it. We have no access to your data and cannot retain it."
- **CCPA "Do Not Sell" disclosure (required regardless of whether data is sold):** Add a clearly labeled "Do Not Sell or Share My Personal Information" button in Settings → Privacy. When tapped, show: "DailyArc does not sell, rent, or share your personal information for advertising or monetary consideration. Your habit and mood data stays on your device. If you opted in to weekly emails, your email address is shared with Buttondown (our email delivery service provider) solely for email delivery — Buttondown does not use your information for its own commercial purposes. There is nothing to opt out of." This satisfies CCPA requirements even for apps that do not sell data — the AG enforces the presence of the mechanism.
- **Mood data and GDPR Article 9 (health data):** Mood scores (1-5) and energy levels may arguably constitute "data concerning health" (mental state) under GDPR Art. 9 and WP29 guidance. Conservative approach: the onboarding consent toggle covers mood data processing. Document in privacy policy: "Mood and energy data are processed under your explicit consent (Art. 6(1)(a)). While we do not consider 1-5 mood scores to constitute clinical health data per Recital 35 (no diagnostic context), we apply the same protective standard as HealthKit data — on-device only, never transmitted."
- **GDPR Article 13(2)(f) — Automated decision-making/profiling disclosure:** The CorrelationEngine constitutes profiling under GDPR Art. 4(4) (automated processing to evaluate personal aspects). Add to privacy policy and Settings → Privacy: "DailyArc uses on-device statistical analysis to identify correlations between your habits and mood. This processing is fully automated but produces informational insights only — it does not make decisions that affect you. You can disable insights by not upgrading to Premium, or withdraw consent entirely via Settings → Withdraw Consent."
- **HealthKit consent withdrawal triggers data deletion:** When a user disables a HealthKit metric toggle in Settings, present a confirmation: "Disabling this will also delete previously auto-logged data from HealthKit for this habit. Continue?" If confirmed, delete all `HabitLog` entries where `isAutoLogged == true` for that habit. Retaining HealthKit-sourced data after consent withdrawal violates GDPR Art. 17(1)(b).
- **Data consent summary:** "Your habit and mood data stays on this device. DailyArc never sends your tracking data to external servers. If you optionally provide your email for weekly summaries, it is shared with our email delivery provider (see Privacy Policy)."
- **Biometric data policy (if app lock added in v1.1):** DailyArc does NOT access, store, or process biometric data (Face ID, Touch ID). If an app lock feature is added in v1.1, it will use `LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` which delegates authentication entirely to iOS — the app never sees biometric templates. Document in privacy policy: "DailyArc does not access your biometric data. If you enable app lock, authentication is handled entirely by your device's secure enclave."
- **Mental health disclaimer:** "DailyArc is not a medical device. Mood tracking is for personal awareness only. If you are experiencing mental health concerns, please consult a healthcare professional. Mood-habit correlations shown in this app are statistical observations for personal reflection only. Do not use them to make medical or mental health treatment decisions."
- **First mood check-in disclaimer (Apple Guideline 1.4.1):** On the first-ever mood emoji tap, show a one-time dismissible tooltip card above the mood picker: "DailyArc helps you spot patterns, not diagnose conditions. Talk to a professional about health concerns." Tracked via `@AppStorage("moodDisclaimerShown")`. This satisfies Apple's requirement that health-related disclaimers be visible before users engage with health content.
- **Device transfer/restore protection:** When a user transfers to a new device or restores from backup, Keychain data migrates with the backup (if encrypted backup or iCloud Keychain). On first launch after restore, verify Keychain DOB is present and re-validate age. If Keychain data is missing (unencrypted backup), re-prompt DOB — this is a fresh device and age must be re-verified. Track via `@AppStorage("deviceID")` (random UUID generated on first launch) — if this value is missing but other @AppStorage values exist, the app was likely restored without Keychain, triggering re-verification.

**COPPA turning-13 behavior:** On each launch, recalculate age from stored Keychain DOB. If user was previously blocked (`isCOPPABlocked == true` in Keychain) and has now turned 13, dismiss the block screen and present the onboarding flow from Page 1 (with full consent collection). Clear `isCOPPABlocked` from both Keychain and AppStorage.

**Premium & Billing:**
- "Premium Active ✓" badge if `isPremium == true`
- Or "Upgrade to Premium" button → PaywallView
- "Restore Purchases" link
- **StoreKit states:** idle → loading → success → error (with retry button + error message)

**About:**
- Version number (from `Bundle.main`) — **Settings whimsy:** Tap the version number 5 times to reveal a hidden "Developer" row with a brief message: "Built with ❤️ and too much coffee." + `@AppStorage("devEasterEggFound")` = true (counts toward Detail Arc badge). This is a well-known iOS convention (cf. Android developer mode) that rewards curious users.
- "Send Feedback" button (mailto: link). **Pre-populate email with diagnostic info:** app version, iOS version, device model, free/premium status, days since install — appended below a blank line so user can write their message first. Example: `mailto:support@dailyarc.app?subject=DailyArc%20Feedback&body=%0A%0A---%0AVersion:%201.0%0AiOS:%2017.4%0ADevice:%20iPhone%2015%0APremium:%20Yes`. This reduces back-and-forth for debugging.
- **In-App Help System (Settings → Help & Support):** Embedded help with 15+ FAQ articles accessible offline — NOT just an external web link. Organized by category:
  - **Getting Started (4 articles):** How DailyArc works, how to create habits, how to log mood, how to navigate dates/backfill.
  - **Habits & Streaks (4 articles):** How streaks work, how recovery works (2-per-30-day rule), custom frequencies explained, HealthKit setup with per-habit sync status.
  - **Mood & Insights (3 articles):** What correlation insights mean, why 14 days of data are required, what energy score is used for.
  - **Premium & Billing (3 articles):** What's included in premium, how to restore purchases ("Make sure you're signed into the same Apple ID"), refund process via Apple.
  - **Privacy & Data (3 articles):** Where data is stored (on-device only), how to export data, how to delete all data, device transfer guidance.
  - **Widgets (2 articles):** How to add DailyArc widgets (step-by-step iOS instructions: long-press home screen → + button → search DailyArc), widget shows old data troubleshooting (force-quit and reopen app), why medium/large widgets require premium.
  Each article is a static SwiftUI view — no web dependency, works offline. Add contextual "?" icons (SF Symbol `questionmark.circle`, 16pt, `textTertiary`) on complex screens: correlation cards, HealthKit settings, streak recovery banner, energy picker, widget configuration. Each "?" opens the relevant help article directly.
  **External fallback:** `dailyarc.app/help` mirrors the in-app content for users who find it via search.
  **Support SLA:** Respond to support emails within 48 hours. Auto-reply with help article links + expected response time. Phase support: <1K users = email only; 1K-10K = add FAQ chatbot; 10K+ = evaluate part-time support hire.
  **Canned response templates (prepare pre-launch, 10 minimum):** Restore purchases failure, HealthKit not syncing, streak recovery unavailable, widget shows old data, data transfer to new phone, refund request redirect, premium features explanation, correlation insights explanation, GDPR data request, general bug report acknowledgment.
- **Device Transfer Guidance (in-app Help article + Settings):** "How to move DailyArc to a new phone": (a) Use encrypted iTunes/Finder backup — preserves Keychain and SwiftData, (b) iCloud backup preserves SwiftData but may not preserve Keychain — user will be re-prompted for DOB but habit data survives, (c) recommend exporting data via JSON before transfer as a safety net. Surface as a Help article and as a pro-tip in the export section.
- "Rate on App Store" button → SwiftUI `.requestReview()` environment action (**NOT deprecated `SKStoreReviewController.requestReview()`**). Strategic: auto-trigger after 7-day streak instead of passive link.
- Acknowledgments / Open source licenses

### Screen 7: Paywall (Premium)

- App icon (80pt) at top
- Title: "Unlock Your Full Arc" (bold, 28pt)
- Subtitle: "One payment. Yours forever." (gray, 16pt)
- Feature list (SF Symbol checkmarks, **brand voice — benefit-first, not feature-comparison**):
  - ✓ Track every habit, not just three
  - ✓ See how your habits shape your mood
  - ✓ Get personalized suggestions that grow with you
  - ✓ Explore your trends over weeks and months
  - ✓ Export everything, anytime
  - ✓ Home screen widgets that keep your arc visible
- Large price: **`product.displayPrice`** + " one-time" (bold, 32pt, accent color). **NEVER hardcode "$5.99" — use StoreKit's localized price for international compliance.**
- Smaller: "No subscriptions. No recurring charges." (gray, 14pt)
- **DO NOT mention competitor names or prices** — Apple may reject, and comparison selling contradicts the "Calm" brand value. Let the product's value speak for itself.
- Full-width **"Unlock Your Arc"** button (accent, 50pt height) — NOT "Purchase" (transactional); "Unlock" + "Arc" reinforces brand value
- **Purchase states:** idle → loading spinner → success checkmark → error with retry
- "Restore Purchases" text link below
- "Not now" link at bottom (gray, dismisses sheet). On tap, show brief warm dismissal toast: "No worries — DailyArc is great free too." (reinforces free tier value, reduces buyer's remorse pressure)
- **Paywall trigger strategy (v1.0 — max 5 surfaces, "Calm" brand value):** A brand that promises calm cannot have aggressive monetization. Limit to 5 surfaces maximum:
  1. **Hard limit:** User tries to create 4th habit (free limit: 3)
  2. **Feature gate:** User taps locked Insights tab or premium feature
  3. **Day 14 insight unlock:** After 14 days of data, free users see their single strongest correlation as a brand promise delivery: "Here is what your data reveals." Below: "Want to see all your insights? Unlock your full arc." This gives free users genuine value before asking for money. Shown once via `@AppStorage("hasSeenInsightPaywall")`.
  4. **Onboarding high-intent moment (Page 3):** After the mock Today View interaction on onboarding Page 3, show a brief "Unlock the full arc" premium preview: "Premium includes unlimited habits, mood insights, and detailed stats." with "See Premium" (small text link, not blocking) and "Start Free" (primary button). Dismissible, non-blocking, shown once.
  5. **Settings upgrade button:** Always accessible in Settings → Premium section. Also shows a "Share DailyArc" row below with ShareLink for soft viral loop.
- **Price anchoring:** Below the price, show: "That's {product.displayPrice / 365} a day after your first year." (**Localization note:** Calculate per-day cost dynamically from `product.price / 365` and format with `product.priceFormatStyle`. Handle edge case where `product.price` returns 0 during free promotions.)
- **Lapsed user re-engagement (tiered):** Contextual cards on Today View for returning users, shown once per tier:
  - 14-30 days absent: "Your arc paused. Pick up where you left off." (no premium pitch)
  - 30-60 days absent: "It's been a while. Your data is safe. Start fresh or continue."
  - 60+ days absent: "Welcome back! A lot has changed." + premium users see their last insight as a hook
  - Separate flows for free vs. premium — premium lapsed users should never see a paywall; they already paid.
- **Returning-after-absence greeting variants (2+ week gap detection):** When a user opens the app after ≥14 days of no launches (detected via `@AppStorage("lastOpenDate")`), replace the standard time-of-day greeting with a warm re-engagement variant (shown once per return episode):
  - "Welcome back, {name}. Your arc remembers you."
  - "Hey {name} — it's been a while. Ready to pick up where you left off?"
  - "{name}! Your habits have been waiting. No judgment, just a fresh start."
  - "Good to see you again, {name}. Every arc has pauses — yours continues now."
  Selection: random from pool. These variants set a compassionate tone and reduce the guilt of returning after absence. After displaying once, revert to standard greeting on subsequent opens.
  **Mutual exclusion with re-engagement cards:** Both the returning-after-absence greeting and the lapsed re-engagement card (above) target the same user state. Rule: the greeting replaces the standard greeting (top of Today View); the re-engagement card appears in the habit section. **Show only one per session** — the greeting takes priority (first visible element). The re-engagement card is deferred to the NEXT session if a returning greeting fires. This prevents redundant "welcome back" messaging in the same session.
- **`@AppStorage("isPremium")` is a CACHE only.** True source of truth is `Transaction.currentEntitlements` from StoreKit 2. On each app launch, verify entitlement and update cache. **Optimistic loading:** default to cached value on launch so premium users don't briefly see free tier while entitlement loads.

### Screen 8: PaywallStubView (compile-time dependency management)

A minimal placeholder used in early build steps before StoreKit is integrated:
```swift
struct PaywallStubView: View {
    var body: some View {
        Text("Premium — coming soon")
            .padding()
    }
}
```
Referenced anywhere PaywallView would appear in Steps 1–4. Replaced with real PaywallView in Step 5.

---

## Streak Milestone Celebrations

| Milestone | Celebration | Badge | v1.0 |
|-----------|------------|-------|------|
| 3 days | Inline "Nice start!" toast + haptic | 🌱 First Arc | ✓ |
| 7 days | Inline toast + badge unlock (NO confetti — see escalation below) | 🌿 Rising Arc | ✓ |
| 14 days | Inline toast + badge unlock + insight unlock ceremony (NO confetti) | 🌳 Steady Arc | ✓ |
| 30 days | Full-screen celebration + share card | 🔥 Blazing Arc | ✓ |
| 100 days | Full-screen + golden sparkle ring + share card | 🏆 Golden Arc | ✓ |
| 365 days | Full-screen + annual recap animation + share card | 💎 Complete Arc | ✓ |
| 60 days | Full-screen + unique visual: 60-day arc time-lapse replay | ⭐ Stellar Arc | v1.1 |
| 500 days | Full-screen + particles forming habit emoji | 🌟 Zenith Arc | v1.1 |
| 1000 days | Full-screen + custom "your entire journey" animation | 👑 Immortal Arc | v1.1 |

**v1.0 ships 6 milestone tiers (3/7/14/30/100/365).** The first 4 milestones deliver 95% of emotional value. Days 60/500/1000 are deferred to v1.1 — no user reaches 500 or 1000 for 1.5-3 years. This recovers ~1 week of build time for core quality.

**Celebration message variants (2-3 per tier for variable reward):**
- 3 days: "Your arc begins! 🌱" / "Three days in — your arc is taking shape." / "Day 3 — the first arc is the hardest."
- 7 days: "One week on your arc!" / "7 days — your arc is rising." / "A whole week of building your arc!"
- 14 days: "Two weeks strong!" / "14 days — your arc is becoming a pattern." / "Two weeks of showing up for your arc."
- 30 days: "A month-long arc!" / "30 days. This arc tells a story." / "A whole month. That's an arc worth celebrating."
- 100 days: "100 days of choosing yourself. Your arc speaks for itself." / "One hundred days. This arc is undeniable." / "100 days. If that doesn't prove who you are, nothing will."
- 365 days: "A complete arc!" / "365 days. Your arc has come full circle." / "One year of {habit}. A complete arc — you've earned it."
- **(v1.1) 60 days:** "Two months of arc-building!" / "60 days. That's not luck — that's your arc." / "Two months — this arc is real."
- **(v1.1) 500 days:** "500 days. That's {percentOfYear}% of a year, every single day. You're remarkable." / "500 days. Your arc transcends streaks." / "Five hundred days. An arc for the ages."
- **(v1.1) 1000 days:** "1,000 days. That's nearly 3 years of showing up. If that doesn't prove who you are, nothing will." / "A thousand days of showing up for yourself." / "Immortal arc."
- **Comeback Arc (streak rebuild):** When a user rebuilds a streak to 7+ days after previously losing a streak of 30+ days, show a special celebration + haptic `.success` + share card option. Track via comparing `habit.bestStreak` with `habit.currentStreak` when current reaches 7. This rewards resilience, not just perfection. **Comeback Arc message variants (3):**
  - "Your Comeback Arc! You lost a {previousStreak}-day streak and came back stronger."
  - "You rebuilt. {previousStreak} days fell, and you started again. That takes real strength."
  - "A {previousStreak}-day streak ended. But here you are, 7 days into a new arc. That's the story."
  **Comeback Arc visual:** A broken arc (line splits into two segments with a gap) that reconnects and seals — the gap fills with a golden glow, the two segments merge, then the normal confetti burst plays. Duration: 1.5s for reconnection, then standard confetti. This is the single most emotionally meaningful visual in the app.
- Selection: rotate by deterministic hash — `stableHash(habit.id.uuidString) % variantCount`. **Do NOT use `habit.id.hashValue`** — Swift's `Hashable.hashValue` is randomized per process (SE-0206) and produces different variants on every app launch.
- **`stableHash` implementation (shared utility — used by celebrations, streak loss, and FeatureFlag):**
```swift
/// Deterministic hash for any string — returns a stable UInt64 across app launches.
/// Uses SHA256 truncation (same as FeatureFlag bucketing) for consistency.
import CryptoKit
func stableHash(_ input: String) -> UInt {
    let hash = SHA256.hash(data: Data(input.utf8))
    return hash.prefix(4).reduce(0) { $0 << 8 | UInt($1) }
}
```
Place in a shared `HashUtility.swift` or as a static method on a caseless `enum StableHash`. Referenced by: celebration variant selection, streak loss variant selection, FeatureFlag bucketing.

**Celebration intensity escalation (prevent emotional reward flattening):**
- Days 3-14: inline toast (1 second) + `.success` haptic, no confetti. **Note:** Badge unlocks (Day 3, 7, 14) trigger a separate badge ceremony modal (see badge unlock ceremony spec) — this is distinct from the confetti escalation system. The escalation table governs confetti only.
- Days 30-60: confetti (50 particles, 2 seconds) + toast, `.success` haptic. **Confetti spec:** particle size 8-14pt random, shapes: 60% rectangles (4:1 aspect), 30% circles, 10% habit emoji; colors: brand palette (Sky, Coral, Indigo, premiumGold) at random; velocity: initial burst 400-800pt/s upward with 120° spread, gravity 600pt/s², rotation: random 0-720°/s; fade: alpha 1.0→0.0 over final 0.5s. Dark mode: particle opacity 0.85 (not 1.0). Canvas-rendered, NOT SwiftUI views.
- Days 100: confetti (75 particles, 2.5 seconds) + full-screen overlay + golden sparkle ring, `.success` haptic
- Days 365: confetti (100 particles, 3 seconds) + full-screen + annual recap mini-animation + unique sound, `.success` + `.heavy` haptic
- Days 500-1000: confetti (100 particles, 3 seconds) + full-screen + screen-edge golden glow effect + unique sound, `.success` + `.heavy` haptic sequence
This prevents celebrations from feeling identical across all tiers after the first month.

**Arc metaphor in celebrations:** At 30+ day milestones, the confetti animation includes a brief arc-drawing motion (0.5s) before particles burst — the 270° arc symbol draws itself in accent color, then "shatters" into confetti particles. This reinforces the brand at the most emotionally impactful moments. At 365 days, the arc completes a full circle (360°) symbolizing a complete cycle. **365-day visual payoff spec:** The arc draws from 0° to 360° over 1.5s (slower than normal 0.5s for gravitas) using `.easeInOut` timing, line width 6pt in `premiumGold`, followed by a 0.3s pulse scale (1.0→1.15→1.0) before shattering into 100 gold confetti particles. The full circle briefly holds on screen for 0.5s so users can register the visual completion. This is the single most emotionally significant animation in the app — it must feel earned and unmissable.

**Streak loss compassion (graduated by streak length, rotate variants by `stableHash(habit.id.uuidString)` — NOT `.hashValue`):**
- **Short streaks (3-6 days lost):**
  - "3 days is a great start. Ready for the next arc?"
  - "That was a solid start — your next arc begins now."
- **Medium streaks (7-29 days lost):**
  - "{old streak} {old streak == 1 ? "day" : "days"} is {old streak} more than zero. Ready for the next arc?" (handles singular "1 day" correctly)
  - "That {old streak}-day arc built real discipline. Start the next chapter."
  - "{old streak} days of showing up — that's not nothing."
- **Long streaks (30-99 days lost):**
  - "{old streak} days of effort don't vanish — they're part of your arc forever."
  - "A {old streak}-day arc is something to be proud of. When you're ready, start another."
  - "That was a real arc. Take your time — it'll be here when you come back."
- **Epic streaks (100+ days lost):**
  - "{old streak} days. That arc changed you. The next one will too."
  - "A {old streak}-day arc speaks for itself. No streak can take that away."
  - "You built something real over {old streak} days. That growth is permanent."
- Delivery: warm inline card in habit row (not toast — toasts feel dismissive for this moment). Haptic `.light` (not `.warning`). Shows on first view after streak breaks.
- **Card intensity scales with streak length:** short streaks = simple text card, medium+ = card with `bestStreak` displayed, epic = card with "Comeback Arc" prompt ("When you hit 7 days again, you'll earn a Comeback Arc badge").
- NEVER show: "You lost your streak!" or any punitive language.

**Celebration priority queue (when multiple events fire simultaneously):**
1. Undo toast is suppressed during all-complete celebration (confetti takes priority)
2. Confetti plays first (2 seconds)
3. Streak milestone toast queues after confetti completes
4. Badge unlock ceremony modal queues after milestone toast dismisses
5. Share card prompt appears inside the badge ceremony modal (not separately)
Never stack more than one overlay simultaneously. Use a serial queue with completion handlers.

**Global celebration budget (per-session ceiling):** Maximum 3 celebration events per app session (foreground→background cycle). After the ceiling is reached, subsequent celebrations are silently logged to `@AppStorage("deferredCelebrations")` and shown on next session open. This prevents overwhelming users who complete many milestones in a single session (e.g., streak recovery filling multiple milestones at once). The ceiling counts: confetti events, badge ceremony modals, and milestone toasts. Undo toasts and inline cards (streak loss) do NOT count toward the ceiling.

**Paywall + celebration mutual exclusion:** Paywall triggers #4 (insight teaser, after Day 14) and #8 (weekly insight card) MUST NOT fire during the same session as a celebration event. If a celebration occurs, defer the paywall trigger to the next session. If a paywall is shown first, celebrations proceed normally (paywall is informational, celebrations are emotional). This prevents the emotional high of a milestone from being immediately followed by a monetization ask, which damages brand trust.

**Celebration interruption recovery:** If the app backgrounds during a celebration (confetti, badge ceremony, or milestone overlay):
- On return to foreground: skip remaining animation, show the final state (badge card or milestone toast) immediately.
- Track pending celebrations in `@AppStorage("pendingCelebrations")` (JSON array of event IDs). Clear each entry after it is shown or dismissed.
- If a badge ceremony was interrupted before the user tapped "Nice!" or "Share", re-present the static badge card (no re-animation) on next foreground.
- Confetti that was interrupted is NOT replayed — the moment has passed. Only the informational content (badge earned, milestone reached) is recovered.

**Share cards (v1.0 — NOT deferred, this is the only viral loop):** At milestones 7/30/100/365, show "Share your streak!" button.
**Share card visual spec (per tier):** Rendered via `ImageRenderer` at **1080×1350 (@2x, 4:5 aspect ratio)** for Instagram/social feeds, with **1200×630** variant for Twitter/links. Always rendered in branded mode (Sky-to-Indigo gradient background) regardless of user's `colorScheme` — share cards are marketing assets.
- **7-day:** Sky-to-Indigo gradient, accent arc illustration (270° arc, 3pt stroke), headline in `displaySmall` bold white, "DailyArc" wordmark bottom-right, App Store link QR code bottom-left, recipient CTA below QR. Text overlay: top third for visibility.
- **30-day:** Deeper Sky-to-Indigo gradient, larger arc illustration (fills 40% of card), headline in `displayMedium` bold white.
- **100-day:** Golden-bordered card (4pt `premiumGold` border), golden arc, optional heat map mini-preview (last 100 days, 10×10 grid, decorative).
- **365-day:** Premium card with animated arc render (full 360° circle in `premiumGold`), headline in `displayLarge`.
- **Instagram Stories / TikTok format (1080×1920, 9:16):** Streak number centered vertically at 40% from top. Habit emoji (80pt) above streak number. Arc visualization (270-degree arc motif, 6pt stroke, accent color) rendered at 30% of card height below streak. "#MyDailyArc" hashtag at bottom 20%. "Track your own habits — DailyArc" CTA at bottom 10%. Sky-to-Indigo gradient fills full height. QR code positioned bottom-right at 120×120pt. This is the primary sharing surface for Instagram Stories and TikTok Reels.
- **Reels-ready celebration export (v1.0.1):** "Record Celebration" option captures the confetti/arc animation as a 3-5 second video clip via `ReplayKit` frame capture, exported as .mp4 at 1080×1920 (9:16). Turns every milestone into potential Reels content. The Comeback Arc reconnection animation is especially powerful — the broken arc reconnecting tells a visual story in seconds.
- Common: habit emoji (if not private), streak count, "DailyArc" branding, App Store link. **Branded hashtag:** All share cards include "#MyDailyArc" in the footer text (12pt, `textTertiary`). Also include "@DailyArcApp" handle. When sharing to Instagram specifically (detectable via `UIActivity.activityType`), pre-populate caption text with: "{milestone text} #MyDailyArc #HabitTracking #{N}DayStreak". Background adapts to user's `colorScheme`. Image card rendered via `ImageRenderer` ONLY when user taps Share (lazy, not eager — avoids main-thread contention during celebration). Share card text tiered by milestone: 7 days = "I just hit a 7-day streak with DailyArc!", 30 days = "30 days strong. Built with DailyArc.", 100 days = "100 days. Not stopping. Tracked with DailyArc.", 365 days = "One full arc, complete. 365 days with DailyArc.", 500 days = "500 days. This is who I am. Built with DailyArc.", 1000 days = "1,000 days. A thousand arcs. DailyArc." Each uses warm, personal language that escalates with the achievement. App branding and App Store link included. **CRITICAL for growth:** without this, the app launches with zero viral mechanics. Share via standard `ShareLink`. **Privacy guard:** Do NOT include habit name in share card if it could disclose health data. Check against expanded keyword list (case-insensitive): "medication", "medicine", "meds", "therapy", "therapist", "counseling", "psychiatr", "antidepress", "anxiety", "depression", "PTSD", "sobriety", "sober", "AA", "recovery", "rehab", "blood pressure", "glucose", "insulin", "vitamins", "supplements", "weight", "diet", "pill", "prescription", "mental health", "panic", "OCD", "bipolar", "ADHD". Use generic "a daily habit" for any match. **Per-habit private flag (v1.0):** Add a "Keep private on share cards" toggle in HabitFormView (default: false). When enabled, always use "a daily habit" regardless of name. This is more robust than keyword matching for non-English names and abbreviations. **Localization note:** The English keyword list above is the v1.0 baseline. For Phase 1 locales, add the top-10 health-related keywords per locale (case-insensitive): **German:** "Medikament", "Therapie", "Arzt", "Angst", "Depression", "Nüchternheit", "Blutdruck", "Insulin", "Gewicht", "Psychisch". **Japanese:** "薬", "セラピー", "治療", "不安", "うつ", "断酒", "血圧", "インスリン", "体重", "メンタル". **French:** "médicament", "thérapie", "médecin", "anxiété", "dépression", "sobriété", "tension", "insuline", "poids", "santé mentale". **Spanish:** "medicamento", "terapia", "médico", "ansiedad", "depresión", "sobriedad", "presión arterial", "insulina", "peso", "salud mental". Match against `Locale.current.language.languageCode`; fall back to English list if locale not covered. v1.1 expands to full lists per Phase 2 languages.

---

## Whimsy & Delight

- **Time-of-day greetings** on Today View (all include {name} for consistency):
  - 5 AM–12 PM: "Good morning, {name} ☀️"
  - 12 PM–5 PM: "Good afternoon, {name} 🌤"
  - 5 PM–9 PM: "Good evening, {name} 🌅"
  - 9 PM–5 AM: "Burning the midnight oil, {name}? 🌙"
  - **Streak-aware variants (when user has 7+ day streak on any habit):**
    - Morning: "Morning, {name}! Day {streak} of your arc ☀️"
    - Afternoon: "Keep it going, {name} — {streak} days strong 🌤"
    - Evening: "{streak}-day arc and counting, {name} 🌅"
  - **Day-of-week variants (rotate by `stableHash(dateString)`):**
    - Monday: "Fresh week, {name} — keep building your arc."
    - Friday: "Friday, {name}! Finish the week strong."
    - Saturday: "Weekend arc, {name} — habits don't clock out, but you can take it easy."
    - Sunday: "Sunday wind-down, {name}. Reflect on your week and set up tomorrow."
  - **Seasonal variants (optional, based on month):**
    - Jan: "New year, new arc, {name}."
    - Spring (Mar-May): "Spring energy, {name} — your arc is blooming."
    - Summer (Jun-Aug): "Summer arc, {name} — keep the momentum."
    - Fall (Sep-Nov): "Fresh start energy, {name}."
    - Dec: "End-of-year arc, {name} — finish strong."
  - **Rare variants (1-in-30 probability, long-term delight):** Applied randomly after Day 30+ of total usage:
    - "Day {totalDaysLogged} of your arc. That's more than most people ever track."
    - "Fun fact: you've tapped {totalCompletions} habits. That's dedication."
    - "{name}, your arc is longer than most New Year's resolutions last."
    - "Your arc has been growing for {weeks} weeks. Just thought you should know."
  - Selection priority: rare (1/30 chance) > streak-aware > seasonal > day-of-week > time-of-day (always show the most contextual variant).
- **Empty states with personality (pattern: empathetic acknowledgment → specific next step → arc metaphor):**
  - No habits: "Your arc starts with one habit. Tap + to create it."
  - No mood logged: "How's today's arc shaping up? Tap an emoji to check in."
  - Stats with no data: "Log for {3 - daysLogged} more days to see your mood trends."
  - No stats: "Your arc is just beginning. Create habits and start logging to see your story unfold." (Uses specific count matching the 3-day threshold for mood trend display. When daysLogged >= 3 but < 14: "Your mood trends are here! Keep logging — insights unlock in {14 - daysLogged} days.")
  - Insights locked (with progress): "Keep logging — insights unlock in {14 - daysLogged} more days." + progress bar showing days toward 14. Bridges the motivation valley by showing daily progress toward the unlock.
- **Day 1-2 micro-delight (pre-valley foundation):**
  - **Day 1:** When streak goes 0→1, the streak fire emoji fades in (not just appears) with a tiny ember animation (orange dot that briefly flickers, 0.3s). No toast — let the visual speak.
  - **Day 2:** "Day 2 — you came back!" as a subtle inline text below the streak badge (not a toast — just a temporary label that fades after 3s, `caption` font, `textSecondary`). These cost almost nothing but make the critical first two days feel noticed.
- **Day 3-14 motivation valley mitigation:** This is the highest churn window. Countermeasures:
  - **Day 3:** "3 days in — you're past the hardest part!" toast + Sprout badge unlock. **Paywall collision avoidance:** If the Day 3 engagement paywall trigger (A/B test variant A) would fire on the same session as a celebration, defer the paywall to the NEXT SESSION (not same-session with a delay). Never interrupt or immediately follow a celebration with a paywall — the emotional high must be preserved and not associated with monetization.
  - **Day 5:** Weekly preview card in Today View: "By Day 7, you'll earn your Rising Arc badge."
  - **Day 7:** Full streak celebration + badge + share card (existing)
  - **Day 8:** "One week down! Here's your first weekly trend." Show a mini 7-day bar chart inline in Today View (even for free users) — 7 bars showing daily completion %, accent color filled. This fills the post-Day-7-celebration letdown.
  - **Day 10:** "10 days — your arc is taking shape!" toast
  - **Day 14:** Insight unlock ceremony (existing) — the ultimate motivation cliff reward. **Day 14 insight awareness nudge:** Show a one-time banner at top of Today View: "Your first mood-habit pattern is ready. See what affects your mood." Tapping navigates to Stats → Insights segment. This bridges the gap between data readiness and user awareness for users who don't proactively visit the Stats tab. Tracked via `@AppStorage("insightNudgeShown")`.
  - **Day 15:** "Halfway to 30!" acknowledgment card at top of Today View (gold border, auto-dismisses after tap or 24h). Copy: "15 days — you're halfway to your Blazing Arc badge. Keep going." Bridges the post-insight-unlock motivation dip.
  - **Day 12:** "Two more days until your first insights unlock. You're almost there." Inline card at top of Today View, auto-dismisses after tap.
  - **Day 21:** "3-week arc" toast: "21 days — research shows habits form over weeks of consistent practice. You're building something real." Haptic `.success`. Lightweight, no modal. *(Note: The popular "21-day rule" is a myth from Maxwell Maltz's 1960 observation about self-image, not habit formation. Lally et al. (2010) found the median is 66 days. We avoid perpetuating this myth — instead, we celebrate the milestone without false promises.)*
  - **Days 30-100 "quiet middle" touchpoints (lightweight, not celebrations):**
    - **Day 45:** Inline text below greeting: "Six weeks in. That's longer than most gym memberships last."
    - **Day 60:** Toast: "Two months. Your arc is one of the long ones now." + haptic `.success`
    - **Day 75:** Inline card: "75 days — three quarters of the way to your Golden Arc."
    - **Day 90:** Inline card (gold border): "90 days. Ten more to Gold. Almost there."
    - **Monthly reflection (Day 30+ users, 1st of each month):** Auto-generated stat comparison card: "This month vs last month: you logged {diff}% more. Your most consistent habit: {habit}." Appears at top of Today View, auto-dismisses on tap.
  - **Day 25:** "Stat check" inline card: surfaces the user's strongest correlation improvement over the past 2 weeks. Copy: "Your arc insight: {topHabit} days are your happiest. Keep it going — 5 more days to Blazing Arc." Creates forward momentum toward Day 30. (Premium users see full insight; free users see a teaser version.)
  - **Activation recovery notifications** (existing, Days 1-3) cover the earliest gap
  - **Weekly summary** (existing, Sunday PM) provides mid-valley re-engagement
  These touchpoints ensure no user goes more than 3 days without a progress signal during the critical first two weeks.
  - **Notification-denied users:** If `UNAuthorizationStatus == .denied`, substitute in-app re-engagement: (1) show a "Welcome back!" card at the top of Today View after 48h absence (via `@AppStorage("lastOpenDate")`), (2) enable the Day 5 weekly preview card and Day 10 toast as in-app overlays on next launch instead of push notifications. This ensures the motivation valley is addressed even without notification permission.
- **Loading states with personality (3 variants each, rotate to avoid staleness):**
  - Insights computing: "Crunching your numbers..." / "Connecting the dots..." / "Your arc is taking shape..." (with spinner)
  - Heat map loading full year: "Drawing your arc..." / "Painting 365 days..." / "Mapping your journey..." (with progress bar)
  - HealthKit syncing: "Talking to Health..." / "Syncing your steps..." / "Checking in with Apple Health..." (with pulse animation)
  - Export generating: "Packaging your data..." / "Wrapping up your arc..." / "Almost ready to share..." (with progress %)
  - Selection: rotate by `appOpenCount % 3` for deterministic but varied experience.
- **Error states (authoritative — per Brand Voice Matrix: "Playful, reassuring"):**
  - Save failure: "We hit a bump in your arc. Give it another tap." (with retry button)
  - Generic error: "We lost the thread. Pull to refresh your arc." (with pull-to-refresh)
  - Export failure: "Export hit a snag. Your data is safe — try again." (with retry button)
  - HealthKit failure: "Health couldn't connect right now. Your arc continues — log manually." (with manual log CTA)
  - HealthKit denied: "No worries — you can always log manually. Your arc doesn't depend on it." + inline guide: "To enable later: Settings → Privacy & Security → Health → DailyArc." with "Open Settings" button (`UIApplication.openSettingsURLString`).
  - Import failure: "That file didn't quite fit. Check the format and try again." (with retry button)
  - Correlation compute failure: "Couldn't crunch your patterns. Pull to refresh your arc." (with pull-to-refresh)
  - StoreKit error: "Something went sideways. Tap to try again." (with retry button)
  - Network error (TelemetryDeck): silent — no user-facing error for analytics failure
  - ModelContext save failure: "Your changes didn't stick. Give it another tap." (with retry button). If retry also fails: "Something's off — try closing and reopening DailyArc." with "OK" dismiss. Log failure count to TelemetryDeck.
  - Widget data write failure: silent — widget shows stale data gracefully. Log to TelemetryDeck.
  - Keychain write failure: "Your settings were saved, but some data may not survive a reinstall." (inline footnote in Settings, not blocking). Log `keychain_write_failed` to TelemetryDeck.
  **Error state visual pattern (all errors):** ErrorStateView component with: (1) illustration from Illustration Style Guide (arc motif, 200pt max height), (2) error message in `bodyLarge` centered, (3) retry button (primary, full width, accent) OR contextual CTA below, (4) **"Need help? Contact us" link** below the retry CTA (opens pre-populated feedback email), (5) optional secondary action in `bodySmall` `textTertiary`. Background: `backgroundSecondary`. Corner radius: `cornerRadiusLarge` (16pt). Consistent across all error surfaces — never show a raw error message or empty screen. **StoreKit errors specifically:** Add reassurance copy "You were not charged" and surface "Restore Purchases" button alongside the retry. **Restore Purchases failure state:** "If you purchased on another device or account, make sure you're signed into the same Apple ID. Still having trouble? Contact us." with pre-populated support email.
- **Journaling prompts** rotating in mood notes placeholder (20+ variants to avoid weekly repetition, **ratio: 60% reflective, 25% gratitude, 15% forward-looking** to balance emotional depth with positive framing):
  - "What made you smile today?"
  - "One thing you're grateful for?"
  - "What's on your mind?"
  - "How did you take care of yourself today?"
  - "What challenged you today?"
  - "Who made a difference in your day?"
  - "What would you do differently?"
  - "What are you looking forward to?"
  - "Describe today in one word."
  - "What gave you energy today?"
  - "What drained your energy?"
  - "Name one small win from today."
  - "What did you learn today?"
  - "How did you help someone today?"
  - "What surprised you today?"
  - "What's something you did just for fun?"
  - "What's weighing on your mind?"
  - "What made today a {moodScore} out of 5?"
  - "What habit felt easiest today?"
  - "What would make tomorrow better?"
  - **Arc-metaphor prompts (reinforce brand in the most intimate interaction):**
  - "What's shaping your arc this week?"
  - "Where is your arc heading?"
  - "What part of today's arc would you replay?"
  - "If your arc had a theme this week, what would it be?"
  - "What's one thing your arc taught you recently?"
  - **Habit-aware prompts (dynamic, reference user's data):**
  - "How did {topHabit} feel today?" (substitute user's most-logged habit)
  - "Did any habit surprise you today?"
  - "Which habit are you most proud of this week?"
  - **Energy-contextual prompts:**
  - "Your energy was {energyScore} — what do you think drove that?"
  - "What gave you the most energy today?"
  - **Temporal prompts:**
  - "It's Friday — how did this week's arc take shape?"
  - "End of the month — what's one habit that defined it?"
  - Selection: deterministic based on `stableHash("\(calendar.component(.dayOfYear, from: date))-\(calendar.component(.year, from: date))")` — incorporates year to prevent annual staleness for 365-day users. Dynamic prompts (habit-aware, energy-contextual) are preferred when data is available; fall back to static prompts otherwise.
- **Non-streak achievements:** Not all badges should require consecutive days. Add volume-based badges to reward consistency without perfection:
  - "📊 Inner Arc" — logged mood 50 times (any pattern) — knowing yourself is its own arc — **Ceremony tier: Starter** (inline toast)
  - "🌈 Spectrum Arc" — used all 5 mood scores at least once — the full emotional arc — **Ceremony tier: Starter** (inline toast)
  - "🎯 Century Arc" — 100 total habit completions (cumulative, not streak) — volume, not perfection — **Ceremony tier: Milestone** (modal + chime)
  - "🧘 Mindful Arc" — logged 7 mindful minutes sessions via HealthKit — the quiet arc — **Ceremony tier: Milestone** (modal + chime)
  - "📈 Insight Arc" — 14+ paired mood+habit data points logged — unlocks correlation insights (see insight unlock ceremony) — **Ceremony tier: Summit** (confetti + fanfare)
  - These appear in the Badge Collection alongside streak badges. Ceremony tiers match the streak badge system: Starter=toast, Milestone=modal+chime, Summit=confetti+fanfare, Zenith=custom particles.

- **Easter eggs (v1.0 — ship at least 3 at launch):**
  - New Year's Day: confetti uses gold particles, toast: "New year, new arc begins!" (check `Calendar.current.component(.month/.day)` in greeting logic)
  - App anniversary: on the 1-year anniversary of @AppStorage("firstLaunchDate"), show "Happy DailyArc-iversary! One year of building better habits."
  - **Palindrome streak:** When a streak number is a palindrome ≥ 11 (11, 22, 33, 44, etc.), show a subtle sparkle on the streak number + toast: "Palindrome streak! That's oddly satisfying." Lightweight, delightful, costs nothing.
- **Easter eggs (v1.0 — additional, ship at launch for denser surprise):**
  - 100th app open: subtle "welcome back" message variation — "Welcome back for the 100th time! You really love this, huh?" (track via `@AppStorage("appOpenCount")`)
  - Seasonal accent tint suggestions (optional): warm tones in autumn (Sep-Nov), cool in winter (Dec-Feb) — subtle shift to heat map border tint and greeting emoji
  - Friday the 13th: spooky emoji variant for greeting ("Spooky Friday, {name}! 🎃") — check `Calendar.current.component(.weekday) == 6 && day == 13`
- **Interactive Easter eggs (v1.0 — adds depth beyond passive discovery):**
  - **Tap the app icon on onboarding Page 1** 5 times rapidly: brief bounce animation + playful toast "You found a secret! You're going to like it here." Tracked to prevent repeat.
  - **Long-press the streak fire emoji** on any habit with 50+ day streak: briefly shows the full streak history as an animated arc path (0.5s draw, then fade). Delightful moment that rewards engagement.
  - **Shake gesture on Stats tab** (when device shake detected via `motionBegan`): randomize the heat map colors briefly (0.5s) with rainbow palette, then snap back to brand colors. Toast: "Just checking if you were paying attention." Once per session.

- **Additional Easter eggs (v1.0 — total 8+ at launch):**
  - **"42" streak:** When any habit reaches exactly 42 days, show toast: "The answer to life, the universe, and everything? Showing up 42 days in a row." (Douglas Adams reference)
  - **Pi Day (March 14):** Greeting variant: "Happy Pi Day, {name}! Your arc is approximately 3.14 radians." Check `Calendar.current.component(.month/.day)`.
  - **Valentine's Day (Feb 14):** Heart-shaped confetti particles replace standard shapes for all celebrations on this day. Greeting: "Spreading love through your arc, {name} 💕"

- **Seasonal/holiday themed celebrations (Whimsy):**
  - **New Year's (Jan 1-3):** Gold confetti particles, New Year greeting, "New Year, New Arc" In-App Event.
  - **Spring (Mar-May):** Confetti includes subtle green leaf particles (10% of total, replacing circle shapes). Celebration toasts gain flower emoji variants.
  - **Halloween (Oct 31):** Orange and purple confetti palette. Greeting: "Spooky arc, {name}! 🎃"
  - **Winter holidays (Dec 20-31):** Confetti includes snowflake shapes (10% of total). Greeting variant: "End-of-year arc, {name} — finish strong! ❄️"
  - Seasonal theming is cosmetic only — no functional changes. Respects reduce motion.

- **Easter egg discovery layer:** Add a hidden "🔍 Detail Arc" badge (reframed from "Explorer" — the name should fit the arc metaphor) in BadgesView shown as a "???" silhouette. Finding 5+ Easter eggs unlocks it with a special ceremony: "You found the hidden arcs! You're the kind of person who finds magic in the details." Track discoveries via `@AppStorage("easterEggDiscoveries")` as a comma-separated list of egg IDs (e.g., "newyear,palindrome,tap5,shake,devmode"). This creates a meta-game encouraging exploration without being intrusive. **Ceremony tier: Summit** (not Zenith — Zenith is reserved for 500+ day streaks, and finding Easter eggs is delightful but not transcendent).

- **End-of-year "Your Year in Arc" review** (v1.1 feature): shareable annual recap with total habits logged, best streaks, mood trends, top activities. Title: "Your Year in Arc" — the arc metaphor's biggest payoff.

**Sound design personality (v1.0 — 4 distinct sounds with brand character, cross-reference Design Tokens section for canonical specs):**
  - **Pop** (habit completion): Short, bright, satisfying. Think bubble pop + subtle chime. 0.15s duration. Conveys: "Done!" Personality: crisp, modern, not cute.
  - **Chime** (badge unlock, milestone): Ascending two-note chime. 0.5s duration. Conveys: "Achievement!" Personality: warm, celebratory, not generic.
  - **Fanfare** (major milestone 100+/365+): Mini brass-inspired ascending scale. 1.0s duration (canonical — matches Design Tokens table). Conveys: "Summit moment!" Personality: triumphant but not bombastic.
  - **Settle** (streak loss): Brief descending half-step tone. <0.3s duration. Conveys: "That's okay." Personality: soft, empathetic, NOT punishing. Plays once when a streak break is first displayed (not on every view). Paired with `.light` haptic.
  All sounds respect silent mode (`.ambient` audio category). Each is distinct enough to recognize without seeing the screen — a user should know "that's a badge" vs "that's a habit tap" by sound alone. Source: royalty-free or commission custom. Format: .caf (Core Audio Format), 44.1kHz, 16-bit — see Design Tokens Sound Design table for full synthesis specs. Total bundle size: <100KB for all 4 sounds.

- **First-ever habit completion celebration:** The most emotionally significant tap in the app. When the user completes their very first habit EVER (not just today — lifetime first): special animation (scale pulse + golden sparkle ring, not confetti), haptic `.success`, and toast: "Your arc begins here." Track via `@AppStorage("hasCompletedFirstHabit")`.
- **First-ever mood log celebration:** When the user selects a mood emoji for the very first time (lifetime first, not daily first): subtle golden highlight pulse on the mood card + toast: "Your first reflection — your arc just got richer." + haptic `.success`. Track via `@AppStorage("hasLoggedFirstMood")`. This acknowledges the emotional significance of the first self-reflection act.

- **Weekly Summary notification (default ON — high-retention touchpoint):** Every Sunday at 6 PM (configurable), send a local notification:
  - Title: "Your week in review"
  - Body: "You completed {X} habits this week. Your mood averaged {emoji}. Tap to see your stats."
  - **Weekly summary variants (rotate weekly for variable reward, 8 variants to avoid annual repetition):**
    * "Your arc this week: {X} habits, {emoji} mood. That's {+N} from last week!" (positive delta only)
    * "Your arc this week: {X} habits, {emoji} mood. Every week builds the arc." (negative/zero delta — compassionate, no numbers)
    * "Your best day was {bestDay} — {X} habits nailed."
    * "{X} habits completed, mood averaging {emoji}. Your most consistent: {topHabitEmoji} {topHabitName}."
    * "Your week in numbers: {X} habits, {longestStreak}-day streak on {habitName}, mood at {emoji}."
    * "Another week in your arc: {X} habits logged, mood at {emoji}."
    * "This week's arc: {topHabitEmoji} {topHabitName} was your strongest habit."
    * "{X} habits this week. Your arc keeps growing."
  - Drives Sunday evening reflection + re-engagement. Add toggle in Settings → Notifications.

- **Badge Collection screen:** Badges exist as milestone toasts but need a persistent home. Dedicated **BadgesView** accessible from Stats tab via a 'Badges' button in the "Your Arc" segment header. Per-habit streak badges are also shown inline in PerHabitDetailView. Global badges (Century Club, Data Nerd, Full Spectrum) appear only in BadgesView.
  - Grid of earned badges with dates: "🔥 7 Days (earned Mar 1)", "⭐ 30 Days (earned Mar 24)", etc.
  - Locked badges shown as grayed silhouettes with target: "🏆 100 Days — 72 days to go"
  - Motivational: shows what's next, not just what's been achieved
- **Badge unlock ceremony (tiered visual differentiation — each tier feels unmistakably different):**
  - **Starter tier** (First Arc 3d, Rising Arc 7d, Inner Arc, Spectrum Arc): Inline expanding card (no modal) — badge emoji scales from 0.5→1.0 with spring animation, background pill in `backgroundSecondary`. Completion pop sound + `.success` haptic. Auto-dismisses after 3s or tap.
  - **Milestone tier** (Steady Arc 14d, Blazing Arc 30d, Century Arc, Mindful Arc): Modal card overlay with badge-colored background gradient (badge's associated palette color at 15% opacity) + glow ring (accent at 20%, 60pt radius). Badge emoji 80pt with `.spring(response: 0.5, dampingFraction: 0.5)` entrance. Milestone chime sound. "Share" + "Nice!" buttons.
  - **Summit tier** (Golden Arc 100d, Insight Arc): Modal card + confetti burst (50 particles, 2s) + arc-drawing animation before badge reveal. Fanfare sound. Badge emoji 100pt with golden sparkle ring. "Share" + "Nice!" buttons.
  - **Zenith tier** (Complete Arc 365d, v1.1 Zenith/Immortal): Full-screen takeover with custom particle system (gold dust, not standard confetti) + 365-day arc completion animation + unique sound. Badge emoji 120pt. "Share" + "Nice!" buttons.
  - Common elements: badge name + description, date earned, `.success` haptic. If reduce motion: no animation, static card presentation.
  - **AX5 adaptation:** Badge emoji sizes clamp to a maximum of 80pt (regardless of tier) to prevent exceeding screen dimensions. Modal cards use `.scrollView` wrapper to ensure all content is accessible. Confetti and particle animations are suppressed (reduce motion is likely enabled at AX5).

**Insight unlock ceremony (Day 14):** When the 14th paired mood+habit data point is logged:
- Toast: "Your first insights are ready! Tap to see what your data reveals."
- Badge: "📈 Insight Arc" unlocked — see volume-based badges section. Unlock criteria: 14+ paired mood+habit data points (triggers insight unlock).
- Haptic: `.success`
- If premium: auto-navigate to Insights tab after 2-second delay
- If free: show insight teaser card with "Upgrade to see all insights" CTA

---

## RuleEngine (Services/RuleEngine.swift — ONLY copy)

```swift
/// On-device rule engine — caseless enum (implicitly Sendable, no instances).
/// Follows same pattern as CorrelationEngine: extract Sendable snapshots on @MainActor,
/// compute via Task.detached, return [Suggestion] (Sendable struct).
enum RuleEngine {

    struct Suggestion: Sendable {
        let emoji: String
        let text: String
        let priority: Int // 0 = highest
    }

    /// Sendable snapshot for off-main-actor computation (mirrors CorrelationEngine pattern)
    struct HabitSnapshot: Sendable {
        let id: UUID
        let name: String
        let emoji: String
        let targetCount: Int
        let isArchived: Bool
        let currentStreak: Int
        let startDate: Date
        let frequencyRaw: Int
        let customDays: String
    }

    struct LogSnapshot: Sendable {
        let habitID: UUID
        let date: Date
        let count: Int
        let isRecovered: Bool
    }

    /// RuleEngine's own MoodSnapshot (separate from CorrelationEngine.MoodSnapshot to avoid cross-enum dependency).
    struct MoodSnapshot: Sendable {
        let date: Date
        let moodScore: Int
        let energyScore: Int
    }

    // NOTE: Suggestion struct defined above (emoji, text, priority). Single definition — no duplicates.

    /// Extract snapshots on @MainActor, then call via Task.detached:
    /// ```swift
    /// let habitSnaps = habits.map { RuleEngine.HabitSnapshot(from: $0) }
    /// let logSnaps = logs.map { RuleEngine.LogSnapshot(from: $0) }
    /// let moodSnaps = moods.map { RuleEngine.MoodSnapshot(date: $0.date, moodScore: $0.moodScore, energyScore: $0.energyScore) }
    /// let calendar = Calendar.current  // capture on @MainActor
    /// let suggestions = await Task.detached { @Sendable in
    ///     RuleEngine.generateSuggestions(habits: habitSnaps, logs: logSnaps, moods: moodSnaps, isPremium: isPremium, calendar: calendar)
    /// }.value
    /// ```
    static func generateSuggestions(habits: [HabitSnapshot], logs: [LogSnapshot], moods: [MoodSnapshot], isPremium: Bool, calendar: Calendar) -> [Suggestion] {
        var suggestions: [Suggestion] = []
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!

        // O(L) pre-grouping — avoids O(H*L) filter-per-habit pattern
        let logsByHabitID = Dictionary(grouping: logs.filter { !$0.isRecovered && $0.date >= thirtyDaysAgo }, by: \.habitID)

        for habit in habits where !habit.isArchived {
            let streak = habit.currentStreak
            let monthLogs = logsByHabitID[habit.id] ?? []
            // CORRECT: Divide by APPLICABLE days (not logged days) to avoid inflating rates
            let applicableDays = (0..<30).filter { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                return DateHelpers.shouldAppear(on: date, frequencyRaw: habit.frequencyRaw, customDays: habit.customDays, calendar: calendar) && date >= habit.startDate
            }.count
            let completedDays = monthLogs.filter { $0.count >= habit.targetCount }.count
            let completionRate = applicableDays > 0 ? Double(completedDays) / Double(applicableDays) : 0

            // FREE rules (1, 3, 6, 9)
            if streak > 7 {
                suggestions.append(.init(emoji: "🔥", text: "\(streak)-day streak on \(habit.emoji) \(habit.name). Keep going!", priority: 1))
            }
            if completionRate < 0.5 && applicableDays >= 7 {
                suggestions.append(.init(emoji: "💪", text: "\(habit.emoji) \(habit.name) is at \(Int(completionRate * 100))% this month — small steps count!", priority: 2))
            }
            // ... (streak recovery, all-complete rules)

            // PREMIUM rules (2, 4, 5, 7, 8, 10, 11, 12)
            guard isPremium else { continue }
            if streak > 30 {
                suggestions.append(.init(emoji: "🏆", text: "\(streak) days of \(habit.emoji) \(habit.name). This arc speaks for itself.", priority: 0))
            }
            // ... (mood correlation, weekday/weekend diff, energy correlation, etc.)
        }

        return suggestions.sorted { $0.priority < $1.priority }
    }
}
```

**CRITICAL: RuleEngine lives ONLY in Services/. The v1 spec had a duplicate in Models/ — remove it.**
**RuleEngine is a caseless `enum` with static methods (same pattern as CorrelationEngine).** This makes it implicitly `Sendable` and eligible for `Task.detached` without `@MainActor` contradiction. Do NOT use `@MainActor class` — that contradicts the `Task.detached` requirement for off-main-thread computation.

---

## StreakEngine (Services/StreakEngine.swift)

```swift
/// IMPORTANT: StreakEngine updates cached properties on the Habit model but does NOT call context.save() directly.
/// The calling code's DebouncedSave handles persistence. This prevents StreakEngine from bypassing the 300ms debounce.
/// NOTE: Explicitly annotated @MainActor — all callers must be on @MainActor. This ensures Calendar.current
/// reflects user locale/timezone settings (same rationale as CorrelationEngine's calendar parameter requirement).
@MainActor final class StreakEngine {
    // NOTE: @MainActor provides Sendable safety via actor isolation — no explicit : Sendable needed.
    // Adding Sendable is technically valid but misleading: it implies free cross-isolation passing,
    // but all methods still require @MainActor context.

    /// nonisolated init allows StreakEngine to be created in @State without @MainActor context.
    /// All methods are @MainActor-isolated, so actual work still runs on main actor.
    nonisolated init() {}

    /// Cold-launch streak reconciliation time budget (ms). If reconciliation exceeds this,
    /// bail after current habit and defer remainder to next foreground cycle.
    /// Measured via `ContinuousClock`. Prevents janky first-frame when user has many habits.
    static let coldLaunchBudgetMs: Int = 200

    /// Recalculate and cache streaks on the Habit model
    /// Call this ONLY when a HabitLog is created, updated, or deleted
    /// PERFORMANCE: Pass pre-fetched logs instead of traversing habit.logs (avoids relationship fault on every call).
    /// Caller fetches once via FetchDescriptor, passes relevant logs.
    /// isDeletion: true when called after a log deletion/undo/recovery (forces full bestStreak recompute).
    /// false on normal completion (uses incremental O(1) bestStreak update).
    /// `isFirstCallToday`: REQUIRED parameter (no default) — forces caller to track via `streakUpdatedToday: Set<UUID>`.
    /// Pass `true` only on the first call for this habit today. Prevents double-increment on multi-count habits.
    /// `calendar`: REQUIRED parameter — caller must pass `Calendar.current` captured on @MainActor.
    /// Matches CorrelationEngine pattern. Prevents timezone bugs if this function is ever called from a non-main context
    /// (e.g., post-import reconciliation).
    func recalculateStreaks(for habit: Habit, logs: [HabitLog], isDeletion: Bool = false, isFirstCallToday: Bool, calendar: Calendar) {
        let today = calendar.startOfDay(for: Date())
        // CRITICAL: Include isRecovered logs in streak calculation — that's the whole point of recovery.
        // Only CorrelationEngine and RuleEngine exclude isRecovered logs (for data integrity).
        let completedDates = Set(
            logs
                .filter { $0.count >= habit.targetCount }
                .map { calendar.startOfDay(for: $0.date) }
        )

        // CRITICAL FIX (B4): Start from yesterday if today has no completed log
        // Otherwise users see "🔥 0" every morning until they log
        let todayCompleted = completedDates.contains(today)
        // IMPORTANT: checkDate is initialized at function scope so both incremental and full
        // recalculation paths can use it. For the incremental path, checkDate starts at today or
        // yesterday; for the full path, it may be walked further back.
        var checkDate = todayCompleted ? today : calendar.date(byAdding: .day, value: -1, to: today)!

        // OPTIMIZATION: On non-deletion (normal completion), skip the O(d) backward walk
        // if we can determine the result without it. The full recalculation is idempotent,
        // so the optimization is purely about performance, not correctness.
        //
        // IMPORTANT: The incremental path must NOT double-count. On rapid taps or multi-count
        // habits, recalculateStreaks may be called multiple times for the same day.
        //
        // ENFORCEMENT: The `isFirstCallToday` parameter is REQUIRED (no default value).
        // The caller (TodayViewModel) maintains `@State private var streakUpdatedToday: Set<UUID>`
        // reset on date change. Call pattern:
        //   let isFirst = !streakUpdatedToday.contains(habit.id)
        //   if isFirst { streakUpdatedToday.insert(habit.id) }
        //   streakEngine.recalculateStreaks(habit: habit, logs: logs, isDeletion: false, isFirstCallToday: isFirst)
        //
        // The incremental O(1) path fires ONLY when ALL conditions are met:
        //   (a) not a deletion, (b) today is completed, (c) most recent applicable day was completed,
        //   (d) isFirstCallToday is true (enforced by function signature, not comment).
        // If isFirstCallToday is false, falls through to full O(d) recalculation (safe, idempotent).
        if !isDeletion && isFirstCallToday && todayCompleted && habit.currentStreak > 0 {
            // Find most recent applicable day before today (not hardcoded yesterday — non-daily habits
            // may have gaps between applicable days, e.g., Mon/Wed/Fri habit checked on Wednesday
            // should look back to Monday, not Tuesday)
            var prevDay = calendar.date(byAdding: .day, value: -1, to: today)!
            while !habit.shouldAppear(on: prevDay, calendar: calendar) && prevDay > habit.startDate {
                prevDay = calendar.date(byAdding: .day, value: -1, to: prevDay)!
            }
            let prevDayCompleted = completedDates.contains(prevDay)
            if prevDayCompleted {
                habit.currentStreak = habit.currentStreak + 1
                habit.bestStreak = max(habit.bestStreak, habit.currentStreak)
                return
            }
        }

        // FULL RECALCULATION PATH (deletion, first calc, streak recovery, or streak was 0):
        // Current streak: count consecutive applicable days backward
        var current = todayCompleted ? 1 : 0
        if !todayCompleted {
            // Check if yesterday (or most recent applicable day) is completed
            while !habit.shouldAppear(on: checkDate, calendar: calendar) && checkDate > habit.startDate {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            }
            if completedDates.contains(checkDate) {
                current = 1
            } else {
                habit.currentStreak = 0
                habit.bestStreak = computeBestStreak(habit: habit, completedDates: completedDates, calendar: calendar)
                return
            }
        }

        // Walk backward counting consecutive days
        checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        while checkDate >= habit.startDate {
            if !habit.shouldAppear(on: checkDate, calendar: calendar) {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }
            if completedDates.contains(checkDate) {
                current += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        habit.currentStreak = current
        // OPTIMIZED: On completion, use incremental bestStreak update (O(1)).
        // On deletion/undo/recovery, use full recompute (O(n log n)).
        if isDeletion {
            habit.bestStreak = computeBestStreak(habit: habit, completedDates: completedDates, calendar: calendar)
        } else {
            habit.bestStreak = max(habit.bestStreak, current)
        }
        // DO NOT call context.save() here — caller's DebouncedSave handles persistence
        // This prevents StreakEngine from bypassing the 300ms debounce architecture
    }

    /// Compute best streak ever by walking all completed dates.
    /// PERFORMANCE: O(n log n) due to sort. Called ONLY on deletion/undo/recovery path.
    /// On normal completion, the caller uses incremental O(1): max(bestStreak, currentStreak).
    /// Full recompute is needed when bestStreak can decrease (log removed).
    /// NOTE: For users with 365+ days of data, this runs on @MainActor which could cause a brief hitch
    /// on the deletion/undo path. If profiling shows >50ms, extract Sendable date data and compute
    /// via Task.detached, then update the model on return:
    /// ```swift
    /// let dates = completedDates  // Set<Date> is Sendable
    /// let result = await Task.detached { computeBestStreakPure(dates, calendar) }.value
    /// habit.bestStreak = result
    /// ```
    /// For v1.0, synchronous-on-main is acceptable given typical data sizes (<365 entries).
    private func computeBestStreak(habit: Habit, completedDates: Set<Date>, calendar: Calendar) -> Int {
        guard !completedDates.isEmpty else { return 0 }
        let sorted = completedDates.sorted()
        var best = 1, current = 1

        for i in 1..<sorted.count {
            var expectedDate = calendar.date(byAdding: .day, value: 1, to: sorted[i-1])!
            // Skip non-applicable days
            while !habit.shouldAppear(on: expectedDate, calendar: calendar) && expectedDate < sorted[i] {
                expectedDate = calendar.date(byAdding: .day, value: 1, to: expectedDate)!
            }
            if sorted[i] == expectedDate {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    /// Check if streak recovery is possible (missed 1-2 applicable days)
    /// LIMIT: Maximum 2 recoveries per 30-day rolling window per habit (prevents gaming).
    /// Track via `UserDefaults.standard.data(forKey: "allRecoveryDates")` — a JSON-encoded
    /// `Dictionary<String, [String]>` mapping habit UUID string → array of ISO date strings.
    /// NOTE: Uses UserDefaults.standard directly (NOT @AppStorage) because StreakEngine is a
    /// @MainActor class, not a SwiftUI View — @AppStorage is a SwiftUI property wrapper that
    /// only functions inside View/App/Scene conforming types. "Delete All My Data" clears
    /// this single key. Maximum 2 dates per habit in rolling 30-day window.
    /// PRUNING: On every read, strip entries older than 30 days and remove empty habit keys.
    /// This prevents unbounded growth over months/years of use.
    func streakRecoveryAvailable(for habit: Habit, logs: [HabitLog], calendar: Calendar) -> (available: Bool, missedDates: [Date]) {
        let today = calendar.startOfDay(for: Date())
        // 1. Collect last 3 applicable days (walk backward, max 7 days scan)
        var applicableDays: [Date] = []
        var scanDate = calendar.date(byAdding: .day, value: -1, to: today)!
        for _ in 0..<7 {
            if habit.shouldAppear(on: scanDate, calendar: calendar) {
                applicableDays.append(scanDate)
                if applicableDays.count == 3 { break }
            }
            scanDate = calendar.date(byAdding: .day, value: -1, to: scanDate)!
        }
        guard !applicableDays.isEmpty else { return (false, []) }

        // 2. Check each applicable day for completion
        let completedDates = Set(logs.filter { $0.count >= habit.targetCount }.map { calendar.startOfDay(for: $0.date) })
        let missedDates = applicableDays.filter { !completedDates.contains($0) }
        guard missedDates.count >= 1 && missedDates.count <= 2 else { return (false, []) }

        // 3a. Verify there's an active streak to recover (day before earliest miss was completed)
        let earliestMiss = missedDates.sorted().first!
        var prevDay = calendar.date(byAdding: .day, value: -1, to: earliestMiss)!
        while !habit.shouldAppear(on: prevDay, calendar: calendar) && prevDay > habit.startDate {
            prevDay = calendar.date(byAdding: .day, value: -1, to: prevDay)!
        }
        guard completedDates.contains(prevDay) else { return (false, []) }

        // 3b. Rolling 30-day recovery count check (<2 allowed)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        if let data = UserDefaults.standard.data(forKey: "allRecoveryDates"),
           let allDates = try? JSONDecoder().decode([String: [String]].self, from: data),
           let habitDates = allDates[habit.id.uuidString] {
            let recentCount = habitDates.compactMap { ISO8601DateFormatter().date(from: $0) }
                .filter { $0 >= thirtyDaysAgo }.count
            guard recentCount < 2 else { return (false, []) }
        }

        return (true, missedDates.sorted())
    }

    /// Apply streak recovery by backfilling HabitLogs
    /// CRITICAL: Logs are marked isRecovered=true to distinguish from real data
    /// TRANSACTION SAFETY: All recovery logs should be created as a batch before triggering save.
    /// If any log creation fails, revert all by not calling debouncedSave.trigger(). The caller
    /// should wrap this in a do/catch and only trigger save on full success.
    func applyRecovery(for habit: Habit, dates: [Date], context: ModelContext, calendar: Calendar) {
        for date in dates {
            let log = HabitLog.fetchOrCreate(habit: habit, date: date, context: context, calendar: calendar)
            log.count = habit.targetCount
            log.isRecovered = true  // Distinguishable from real completions
        }
        // Re-fetch logs for this habit after mutations
        let habitID = habit.id
        let descriptor = FetchDescriptor<HabitLog>(predicate: #Predicate { $0.habitIDDenormalized == habitID })
        let allLogs = (try? context.fetch(descriptor)) ?? []
        recalculateStreaks(for: habit, logs: allLogs, isDeletion: false, isFirstCallToday: false, calendar: calendar)
    }
}
```

---

## DebouncedSave (Utilities/DebouncedSave.swift)

```swift
/// Coalesces rapid SwiftData writes into a single save() after 300ms of inactivity.
/// Prevents write storms when user rapidly taps habits (each tap → fetchOrCreate → property change → @Query observation).
/// Usage: call debouncedSave.trigger() instead of context.save() in all main-actor auto-save paths.
/// NOTE: Not @Observable — this is infrastructure, not view state. Observing it would cause
/// unnecessary view invalidations on every save cycle. Only `lastError` needs to surface to UI;
/// expose it via a Combine publisher or callback, not @Observable property tracking.
@MainActor
final class DebouncedSave {
    private let context: ModelContext
    private let delay: Duration
    var userCalendar: Calendar  // Re-captured on .scenePhase == .active (see timezone strategy, rule 7)
    private var pendingTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?  // Separate from pendingTask to avoid orphaning

    init(context: ModelContext, delay: Duration = .milliseconds(300), calendar: Calendar = .current) {
        self.context = context
        self.delay = delay
        self.userCalendar = calendar
    }

    /// Published error state — observe from View to show non-blocking alert.
    /// Use a simple property + NotificationCenter or callback instead of @Observable.
    private(set) var lastError: Error?
    var onError: (@Sendable (Error) -> Void)?  // Callback for UI to observe errors without @Observable overhead. @Sendable for Swift 6 forward compatibility.
    private var retryCount = 0
    private let maxRetries = 1

    /// Bypass debounce — save immediately. Use for streak-critical, mood, and recovery writes.
    /// Does NOT cancel retryTask or reset retryCount — only flushes current state.
    func triggerImmediate() {
        pendingTask?.cancel()
        pendingTask = nil
        performSave()
    }

    /// Call this after every model mutation. Cancels any pending save AND any pending retry,
    /// then restarts the timer. This ensures a new user action always takes priority over retries.
    func trigger() {
        pendingTask?.cancel()
        retryTask?.cancel()  // Cancel retry too — new data supersedes retry of stale save
        retryCount = 0
        pendingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.delay)
            guard !Task.isCancelled else { return }
            self.performSave()
        }
    }

    /// Force immediate save (use for app backgrounding via .scenePhase)
    func flush() {
        pendingTask?.cancel()
        retryTask?.cancel()
        pendingTask = nil
        retryTask = nil
        retryCount = 0
        performSave()
    }

    private func performSave() {
        // GDPR consent withdrawal: skip save if consent is withdrawn (data remains but no new processing).
        // NOTE: The UI layer MUST disable all data input (habit taps, mood logging) when consent is withdrawn.
        // This guard is a safety net — the user should never reach performSave() in withdrawn state because
        // TodayView checks `gdprConsentWithdrawn` and shows read-only mode with disabled controls.
        guard !UserDefaults.standard.bool(forKey: "gdprConsentWithdrawn") else { return }
        do {
            try context.save()
            do {
                let widgetStart = ContinuousClock.now
                try WidgetDataService.writeNow(context: context, calendar: userCalendar)
                let widgetDuration = ContinuousClock.now - widgetStart
                if widgetDuration > .milliseconds(50) {
                    // Circuit breaker: log slow widget writes. If consistently >50ms,
                    // skip widget update for this cycle and rely on next save cycle.
                    TelemetryDeck.signal("widget_write_slow", parameters: ["duration_ms": "\(Int(widgetDuration / .milliseconds(1)))"])
                }
            } catch { /* Widget write failures must not affect save success path — log to TelemetryDeck but do not propagate */ }  // Sync widget data on every successful save (see Step 7b). Wrapped in do/catch because JSONEncoder failure on malformed widget data should not interrupt the save success flow.
            lastError = nil
            retryCount = 0
        } catch {
            if retryCount < maxRetries {
                retryCount += 1
                // Retry once after short delay — stored in retryTask (not pendingTask)
                // so trigger() can cancel it independently
                retryTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .milliseconds(500))
                    guard let self, !Task.isCancelled else { return }
                    self.performSave()
                }
            } else {
                lastError = error
                retryCount = 0
                onError?(error)
                // Surface error to UI — View observes via onError callback:
                // "Your changes may not have been saved. Try closing and reopening the app."
            }
        }
    }
}
```

**Usage pattern in TodayView:**
```swift
// In TodayView (or any view with auto-save):
@Environment(\.modelContext) private var context
@State private var debouncedSave: DebouncedSave?
@State private var streakEngine = StreakEngine()  // Single instance — reused across taps
// NOTE: @State is used intentionally for lifecycle management (prevents re-creation on view updates).
// StreakEngine is NOT @Observable — @State here is purely for ownership, not observation.

// CRITICAL: Guard against re-creation on repeated .onAppear (tab switches, sheet dismissals).
// Without this guard, each re-creation orphans the previous Task and loses pending saves.
.onAppear { if debouncedSave == nil { debouncedSave = DebouncedSave(context: context) } }

// On habit tap:
let calendar = debouncedSave?.userCalendar ?? Calendar.current
let log = HabitLog.fetchOrCreate(habit: habit, date: selectedDate, context: context, calendar: calendar)
log.count = min(log.count + 1, habit.targetCount)
// Fetch logs for this habit (single query, no relationship fault)
let habitID = habit.id
let logDescriptor = FetchDescriptor<HabitLog>(predicate: #Predicate { $0.habitIDDenormalized == habitID })
let habitLogs = (try? context.fetch(logDescriptor)) ?? []
let isFirst = !streakUpdatedToday.contains(habit.id)
streakEngine.recalculateStreaks(for: habit, logs: habitLogs, isFirstCallToday: isFirst, calendar: calendar)  // Mutates habit, does NOT save
streakUpdatedToday.insert(habit.id)
// Streak-critical: immediate save when habit reaches targetCount
if log.count >= habit.targetCount && (log.count - 1) < habit.targetCount {
    debouncedSave?.triggerImmediate()  // Streak-changing — bypass debounce
} else {
    debouncedSave?.trigger()  // Non-critical — coalesce into single save after 300ms
}

// Scene phase handling:
.onChange(of: scenePhase) {
    switch scenePhase {
    case .active:
        // Re-capture Calendar.current on foreground return (timezone/locale may have changed)
        debouncedSave?.userCalendar = Calendar.current
    case .inactive:
        debouncedSave?.flush()  // .inactive fires before .background — earlier save opportunity
    default: break
    }
}
```

**Save-criticality tiers:** Not all mutations deserve debouncing. Add a `triggerImmediate()` method that bypasses debounce and calls `performSave()` directly. Use for:
- **Streak-changing completions:** When a HabitLog transitions from `count < targetCount` to `count >= targetCount`, this is a streak-critical event. Call `triggerImmediate()` instead of `trigger()` to prevent data loss if the app is terminated during the 300ms window.
- **Mood logs:** First mood log of the day (emotional significance warrants immediate persistence).
- **Streak recovery operations:** User explicitly chose to recover — losing this would be frustrating.
Rapid count increments on multi-count habits (count 1→2→3 on a targetCount=5 habit) continue to use the debounced `trigger()`.

**CRITICAL (v28 reconciliation):** `DebouncedSave` debounces the *dispatch* to `HabitLogWriteActor`, not a direct `context.save()` on the main context. The main context is read-only for HabitLog/MoodEntry writes (see rule at line ~411). The `performSave()` method in the code block above should be updated during implementation to call `await HabitLogWriteActor.shared.commitPendingChanges()` instead of `context.save()` directly. The code block above shows the debounce/retry logic pattern; the actual write destination is the single write actor. `WidgetDataService` writes synchronously from the write actor's success path (no independent debounce — see Step 7b).

**Lifecycle safety:** `DebouncedSave` holds a reference to `ModelContext`. If the owning View's scene is destroyed, the `ModelContext` may become stale. Mitigations: (1) `DebouncedSave` is `@State` on the View, so it is destroyed with the View, (2) both `pendingTask` and `retryTask` use `[weak self]`, so they do not prevent deallocation, (3) `flush()` on `.inactive` scene phase ensures pending data is saved before potential termination (fires before `.background`, giving an earlier save opportunity). **Known limitation:** If the app is force-killed from the app switcher while in foreground, pending saves within the 300ms debounce window are lost. Accepted as technical debt — the 300ms window makes this extremely unlikely to affect real data.

---

## HealthKit Integration (Services/HealthKitService.swift)

```swift
/// CRITICAL (v30): HealthKitModelActor is REPLACED by HabitLogWriteActor (see line ~429).
/// All writes — including HealthKit — route through the single write actor.
/// This code block is retained for reference but should NOT be implemented as a separate actor.
/// Instead, call HabitLogWriteActor.shared.saveLog(habitID:date:count:isAutoLogged:true:calendar:)
/// from the HealthKit observer callback.
///
/// LEGACY CODE (pre-v28 — do NOT implement as separate actor):
@ModelActor
actor HealthKitModelActor_LEGACY_SEE_HabitLogWriteActor {
    /// Write HealthKit data to SwiftData safely from background queue
    /// Uses habit.id (UUID) for lookup — persistentModelID may not be stable across actor boundaries
    /// Calendar parameter: caller captures `Calendar.current` on @MainActor before dispatching to this actor.
    /// Matches CorrelationEngine/RuleEngine/StreakEngine pattern — prevents timezone divergence on non-main actors.
    func createOrUpdateLog(habitID: UUID, date: Date, count: Int, calendar: Calendar) throws {
        var descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitID }
        )
        descriptor.fetchLimit = 1
        guard let habit = try modelContext.fetch(descriptor).first else { return }
        let log = HabitLog.fetchOrCreate(habit: habit, date: date, context: modelContext, calendar: calendar)
        // Preserve isAutoLogged provenance: if log already exists with isAutoLogged=true, keep it.
        // This prevents the main context from overwriting HealthKit provenance on merge.
        if !log.isAutoLogged { log.isAutoLogged = true }
        log.habitIDDenormalized = habit.id  // Ensure denormalized field is populated (may be first creation)
        log.count = max(log.count, count)  // Don't overwrite higher manual count
        // INTENTIONAL: Direct save() here is correct — @ModelActor has its own isolated ModelContext,
        // so it doesn't conflict with the main actor's DebouncedSave. This is the one exception
        // to the "no direct save" rule because actor isolation guarantees no write contention.
        try modelContext.save()

        // POST-SAVE DEDUP CHECK: After saving, verify no duplicate HabitLog was created
        // by a concurrent main-context write. Race window: main actor tap → fetchOrCreate +
        // HealthKit observer → fetchOrCreate can overlap if both fire within the 300ms debounce.
        // Query for all logs matching habit+date; if count > 1, merge (keep highest count, delete extras).
        let normalizedDate = calendar.startOfDay(for: date)
        var dedupDescriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { $0.habitIDDenormalized == habitID && $0.date == normalizedDate }
            // NOTE: Uses habitIDDenormalized (consistent with fetchOrCreate) — avoids optional-chaining
            // through @Relationship that may not be faulted in on @ModelActor context.
        )
        let duplicates = (try? modelContext.fetch(dedupDescriptor)) ?? []
        if duplicates.count > 1 {
            let keeper = duplicates.max(by: { $0.count < $1.count })!
            for dup in duplicates where dup.id != keeper.id {
                modelContext.delete(dup)
            }
            try? modelContext.save()
        }
        // Post-save: notify main actor to recalculate streaks for affected habit.
        // HealthKitModelActor cannot call @MainActor StreakEngine directly.
        // Use NotificationCenter to bridge: post .habitLogUpdatedFromHealthKit with habitID.
        // TodayView observes this notification and calls streakEngine.recalculateStreaks().
        NotificationCenter.default.post(name: .habitLogUpdatedFromHealthKit, object: habitID)
        // Define: extension Notification.Name { static let habitLogUpdatedFromHealthKit = Notification.Name("habitLogUpdatedFromHealthKit") }
        // **CRITICAL (Swift 6):** Observers MUST dispatch to MainActor. Use `.task` modifier:
        // ```swift
        // .task {
        //     for await notification in NotificationCenter.default.notifications(named: .habitLogUpdatedFromHealthKit) {
        //         guard let habitID = notification.object as? UUID else { continue }
        //         await MainActor.run { streakEngine.recalculateStreaks(for: habitID) }
        //     }
        // }
        // ```
        // SwiftUI's `.task` modifier automatically cancels the task when the view disappears,
        // including edge cases where `.onDisappear` is not called (lazy tab rendering, conditional
        // view removal). This eliminates the task leak risk of manual `.onAppear`/`.onDisappear`.
        // Do NOT use `.receive(on: DispatchQueue.main).sink { ... }` — fails Sendable checking in Swift 6.
        //
        // **Tab switch resilience:** `.task` cancels when the view disappears, which happens on
        // tab switches in TabView. To maintain the observer across tab switches, attach the `.task`
        // modifier to ContentView (parent of TabView), NOT to TodayView. This ensures the
        // notification listener persists for the app's lifetime. Alternative: use `.task(id:)` with
        // a stable ID that doesn't change on tab switch. The observer itself is lightweight (async
        // for-await loop) so keeping it alive is negligible cost.
    }
}

/// **HabitLogWriteActor lifecycle (replaces HealthKitModelActor):** Created once in `DailyArcApp.init()`
/// alongside `ModelContainer`, stored as `@State private var writeActor: HabitLogWriteActor`.
/// Passed to HealthKitService via `registerObserver(habitID:typeRaw:writeActor:)`. The actor shares
/// the same `ModelContainer` as the main context. It is never recreated — if the app is backgrounded
/// and resumed, the existing instance is reused. Both user taps (via DebouncedSave dispatch) and
/// HealthKit callbacks route through this single actor. On `willTerminate`, no explicit teardown
/// needed (actor isolation guarantees no in-flight writes escape).

/// Actor isolation makes HealthKitService safe to call from any context (Swift 6 compliant).
/// HKHealthStore methods are already thread-safe, but actor isolation prevents data races on any future mutable state.
@preconcurrency import HealthKit  // Required for Swift 6 strict concurrency — HKHealthStore and related types lack full Sendable conformance
actor HealthKitService {
    private let store = HKHealthStore()

    /// Request authorization — accepts both quantity and category types
    /// NOTE: HKHealthStore.requestAuthorization returns Void (not Bool). Success = no throw.
    func requestAuthorization(for typeIdentifier: String) async throws {
        var readTypes: Set<HKObjectType> = []
        if let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: typeIdentifier)) {
            readTypes.insert(quantityType)
        } else if typeIdentifier == "HKWorkoutTypeIdentifier" {
            readTypes.insert(HKWorkoutType.workoutType())
        } else if typeIdentifier == "HKCategoryTypeIdentifierMindfulSession" {
            readTypes.insert(HKCategoryType.categoryType(forIdentifier: .mindfulSession)!)
        } else if let categoryType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: typeIdentifier)) {
            readTypes.insert(categoryType)
        }
        try await store.requestAuthorization(toShare: nil, read: readTypes)  // nil = "not requesting write authorization" (semantically correct for read-only; empty Set means "explicitly no write types")
    }

    /// Per-type query strategy (H1, fixes from v4):
    /// - Steps, distance → HKStatisticsCollectionQuery (daily aggregates, quantity types)
    /// - Mindful minutes → HKSampleQuery on HKCategoryType(.mindfulSession) — NOT a quantity type
    /// - Workouts → HKSampleQuery on HKWorkoutType.workoutType()
    /// - Sleep → HKSampleQuery on HKCategoryType(.sleepAnalysis), filter .inBed/.asleepUnspecified
    /// NOTE: HKCategoryQuery does NOT exist. Use HKSampleQuery for all category/workout types.
    /// CRITICAL: Do NOT pass @Model Habit to async methods — same Sendable violation as CorrelationEngine.
    /// Extract habitID + typeRaw on @MainActor BEFORE calling this method.
    /// **10-second timeout per query.** If HealthKit does not respond within 10 seconds
    /// (authorization pending, large Health database), return empty array and log to TelemetryDeck.
    /// Graceful fallback: user can always log manually.
    /// Implementation: Wrap HK queries in withThrowingTaskGroup racing against Task.sleep(for: .seconds(10)).
    /// If timeout wins, call query.stop() and return [].
    func backfillHabitLogs(habitID: UUID, typeRaw: String, days: Int = 30) async -> [(date: Date, count: Int)] {
        switch typeRaw {
        case "HKQuantityTypeIdentifierStepCount",
             "HKQuantityTypeIdentifierDistanceWalkingRunning":
            return await fetchViaStatisticsCollection(identifier: typeRaw, days: days)
        case "HKWorkoutTypeIdentifier":
            return await fetchViaWorkoutSampleQuery(days: days)
        case "HKCategoryTypeIdentifierSleepAnalysis":
            // Use HKSampleQuery with HKCategoryType(.sleepAnalysis) predicate
            // Filter for .inBed or .asleepUnspecified, sum durations per day
            return await fetchViaSleepSampleQuery(days: days)
        case "HKCategoryTypeIdentifierMindfulSession":
            // Mindful minutes is a CATEGORY type, NOT quantity — use HKSampleQuery
            // Sum sample durations per day, convert to minutes
            return await fetchViaMindfulSampleQuery(days: days)
        default:
            return []
        }
    }

    /// Register HKObserverQuery for ongoing sync
    /// CRITICAL: Callback fires on background queue → use HabitLogWriteActor for writes
    /// Pass habitID (UUID) and typeRaw (String) — NOT the @Model Habit object (not Sendable)
    /// **Background task protection:** HKObserverQuery callbacks can fire while the app is suspended.
    /// iOS gives ~30 seconds to complete work. Wrap the modelActor write in a background task via
    /// `BackgroundTaskService` protocol (per rule 40 — `#if canImport(UIKit)` for visionOS portability):
    /// ```swift
    /// let taskID = await BackgroundTaskService.shared.beginTask(name: "HealthKit-\(habitID)")
    /// defer { await BackgroundTaskService.shared.endTask(taskID) }
    /// ```
    /// **BackgroundTaskService implementation (Services/BackgroundTaskService.swift):**
    /// ```swift
    /// protocol BackgroundTaskService: Sendable {
    ///     func beginTask(name: String) async -> UInt
    ///     func endTask(_ id: UInt) async
    /// }
    /// #if canImport(UIKit)
    /// final class UIKitBackgroundTaskService: BackgroundTaskService {
    ///     static let shared = UIKitBackgroundTaskService()
    ///     func beginTask(name: String) async -> UInt {
    ///         await MainActor.run { UInt(UIApplication.shared.beginBackgroundTask(withName: name) {}) }
    ///     }
    ///     func endTask(_ id: UInt) async {
    ///         await MainActor.run { UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: Int(id))) }
    ///     }
    /// }
    /// #else
    /// final class NoOpBackgroundTaskService: BackgroundTaskService {
    ///     static let shared = NoOpBackgroundTaskService()
    ///     func beginTask(name: String) async -> UInt { 0 }
    ///     func endTask(_ id: UInt) async {}
    /// }
    /// #endif
    /// ```
    /// The `@Sendable` closure annotation is required on the observer callback for Swift 6.
    func registerObserver(habitID: UUID, typeRaw: String, writeActor: HabitLogWriteActor) {
        // HKObserverQuery fires when new health data arrives
        // 1. Begin background task via BackgroundTaskService.shared.beginTask()
        // 2. Use modelActor.createOrUpdateLog(habitID:date:count:) for thread-safe SwiftData writes
        // 3. End background task via BackgroundTaskService.shared.endTask()
        // The observer closure captures habitID (UUID, Sendable) not Habit (@Model, not Sendable)
    }

    // MARK: - Private query methods
    private func fetchViaStatisticsCollection(identifier: String, days: Int) async -> [(Date, Int)] { /* HKStatisticsCollectionQuery for quantity types */ }
    private func fetchViaWorkoutSampleQuery(days: Int) async -> [(Date, Int)] { /* HKSampleQuery on HKWorkoutType, count per day */ }
    private func fetchViaSleepSampleQuery(days: Int) async -> [(Date, Int)] { /* HKSampleQuery on HKCategoryType(.sleepAnalysis), sum durations */ }
    private func fetchViaMindfulSampleQuery(days: Int) async -> [(Date, Int)] { /* HKSampleQuery on HKCategoryType(.mindfulSession), sum durations */ }
}
```

**CRITICAL: Never send HealthKit-sourced data (`isAutoLogged == true`) off-device.** This is enforced by architecture (no external API exists), but the filter is a safety net for any future API additions.

**Required Info.plist key (H8):**
```
NSHealthShareUsageDescription = "DailyArc uses HealthKit data to automatically track habits like exercise, steps, and sleep. Your health data stays on your device and is never sent to external servers."
```

---

## Correlation Engine (Services/CorrelationEngine.swift)

Separate from RuleEngine for clarity. Handles all statistical calculations.

```swift
/// CRITICAL: @Model objects are NOT Sendable — they cannot cross actor boundaries.
/// Extract all needed data into plain Sendable structs on the main actor BEFORE dispatching to Task.detached.
/// CorrelationResult stores habitID/habitName (not Habit reference) so it's safe to return.
/// NOTE: Enum with static methods — no instance state needed. This makes CorrelationEngine
/// implicitly Sendable (enums without cases conform to Sendable). Safe for Task.detached { }.
///
/// CANCELLATION: The caller (StatsViewModel) stores the Task handle returned by Task.detached
/// and cancels it on view dismiss or when new computation is requested:
/// ```swift
/// @State private var correlationTask: Task<[CorrelationResult], Never>?
/// // On compute:
/// correlationTask?.cancel()  // Cancel previous in-flight computation
/// correlationTask = Task.detached { @Sendable in CorrelationEngine.computeCorrelations(...) }
/// // On disappear:
/// .onDisappear { correlationTask?.cancel() }
/// ```
/// Inside computeCorrelations, check `Task.isCancelled` between habit iterations to bail early.
/// **Computation time SLA:** computeCorrelations MUST complete within 500ms for 10 habits × 365 days
/// on the oldest supported device (iPhone XS / A12). If computation exceeds 500ms (measured via
/// `ContinuousClock`), bail after current habit, return partial results, and log `correlation_timeout`
/// to TelemetryDeck with habit count and elapsed time. The 500ms budget prevents the Insights
/// tab from feeling sluggish on older devices.
///
/// **Habit cap for v1.0:** Process the 10 most-recently-active habits (sorted by `lastLogDate`
/// descending). If user has >10 habits, compute top 10 within SLA, then schedule remaining habits
/// as a background retry at `.utility` priority. Log `correlation_habits_capped` when this triggers.
/// This ensures power users with 20+ habits still get fast initial results.
///
/// **Partial-results contract (full specification):**
/// 1. **Return type:** `CorrelationResult` gains an `isPartial: Bool` property.
/// 2. **UI indicator:** When `isPartial == true`, show inline qualifier below the correlation list:
///    "Based on partial analysis ({N} of {total} habits)" in `bodySmall`, `textTertiary`.
///    Do NOT show a blocking error or empty state — partial results are still valuable.
/// 3. **Follow-up task:** When partial results are returned, schedule a `Task.detached` retry
///    with lower priority (`.utility`) that computes the remaining habits. On completion,
///    update the UI via `@Published` property. If the user navigates away before retry completes,
///    cancel via `correlationRetryTask?.cancel()`.
/// 4. **"Not yet computed" distinction:** If `computeCorrelations` returns zero results AND timed
///    out (i.e., couldn't complete even the first habit), display: "Still crunching your data —
///    check back in a moment." with a subtle progress indicator. This is distinct from "not enough
///    data" (which shows the Day 14 data collection progress message).
/// 5. **Telemetry:** Log `correlation_timeout` with `habit_count`, `habits_completed`, `elapsed_ms`.
///    If >10% of sessions produce timeouts, investigate algorithm optimization for v1.0.1.
enum CorrelationEngine {

    /// Sendable input struct — extract from @Model on main actor before dispatching
    struct HabitSnapshot: Sendable {
        let id: UUID
        let name: String
        let emoji: String
        let targetCount: Int
        let frequencyRaw: Int
        let customDays: String
        let startDate: Date
        let logs: [LogSnapshot]  // Pre-filtered: excludes isRecovered
    }

    struct LogSnapshot: Sendable {
        let date: Date
        let count: Int
    }

    struct MoodSnapshot: Sendable {
        let date: Date
        let moodScore: Int
        let energyScore: Int
    }

    /// Sendable output struct — safe to return across actor boundaries.
    /// Explicit `: Sendable` conformance for consistency with HabitSnapshot/LogSnapshot/MoodSnapshot.
    struct CorrelationResult: Sendable {
        let habitID: UUID       // NOT Habit — @Model is not Sendable
        let habitName: String
        let habitEmoji: String
        let coefficient: Double  // -1.0 to 1.0
        let averageMoodOnHabitDays: Double
        let averageMoodOnSkipDays: Double
        let averageEnergyOnHabitDays: Double
        let strengthLabel: String
        let sampleSize: Int
        let isBinaryHabit: Bool
        var isSignificant: Bool  // Set after Bonferroni correction in computeCorrelations
    }

    /// STEP 1 (call on @MainActor): Extract Sendable snapshots from @Model objects.
    /// CRITICAL: Pass pre-fetched logs via a single FetchDescriptor query — do NOT traverse habit.logs
    /// (each traversal triggers a relationship fault = N+1 queries for N habits).
    @MainActor
    static func extractSnapshots(habits: [Habit], allLogs: [HabitLog], moods: [MoodEntry]) -> ([HabitSnapshot], [MoodSnapshot]) {
        // Group logs by habit ID in one pass — uses habitIDDenormalized to avoid N+1 relationship faults.
        // CRITICAL: habitIDDenormalized MUST be populated on creation (see fetchOrCreate + HabitLogWriteActor).
        let logsByHabitID = Dictionary(grouping: allLogs.filter { !$0.isRecovered }) { $0.habitIDDenormalized }

        let habitSnapshots = habits.map { habit in
            let logs = logsByHabitID[habit.id] ?? []
            return HabitSnapshot(
                id: habit.id, name: habit.name, emoji: habit.emoji,
                targetCount: habit.targetCount, frequencyRaw: habit.frequencyRaw,
                customDays: habit.customDays, startDate: habit.startDate,
                logs: logs.map { LogSnapshot(date: $0.date, count: $0.count) }
            )
        }
        let moodSnapshots = moods.map { MoodSnapshot(date: $0.date, moodScore: $0.moodScore, energyScore: $0.energyScore) }
        return (habitSnapshots, moodSnapshots)
    }

    /// STEP 2 (call via Task.detached): Pure computation on Sendable data — no @Model access
    /// NOTE: Caller must capture `Calendar.current` on @MainActor and pass it here.
    /// `Calendar.current` inside Task.detached may not reflect user locale/timezone settings on all iOS versions.
    static func computeCorrelations(habits: [HabitSnapshot], moods: [MoodSnapshot], calendar: Calendar) -> [CorrelationResult] {
        let moodByDate = Dictionary(grouping: moods) { calendar.startOfDay(for: $0.date) }

        let raw = habits.compactMap { habit -> CorrelationResult? in
            let habitLogsByDate = Dictionary(
                grouping: habit.logs,
                by: { calendar.startOfDay(for: $0.date) }
            )

            var habitValues: [Double] = []
            var moodValues: [Double] = []
            var habitDayEnergyValues: [Double] = []  // Energy on habit-completed days (energyScore > 0)
            var skipDayEnergyValues: [Double] = []   // Energy on habit-skipped days (energyScore > 0) — comparison group for energy correlation

            // CANCELLATION: Check between habit iterations to bail early on view dismiss
            guard !Task.isCancelled else { return nil }

            var iterationCount = 0
            for (date, moodEntries) in moodByDate {
                // CANCELLATION: Also check inside inner loop every 50 iterations for habits with 365+ days
                iterationCount += 1
                if iterationCount % 50 == 0, Task.isCancelled { return nil }

                guard let mood = moodEntries.first, mood.moodScore > 0 else { continue }  // Skip unset sentinel (moodScore==0)
                guard mood.moodScore >= 1 && mood.moodScore <= 5 else { continue }  // Range validation — reject corrupted entries
                // Skip dates before this habit existed — prevents artificial "skip day" inflation
                guard date >= habit.startDate else { continue }
                // shouldAppear logic delegates to DateHelpers (no @Model access)
                guard DateHelpers.shouldAppear(on: date, frequencyRaw: habit.frequencyRaw, customDays: habit.customDays, calendar: calendar) else { continue }
                let habitCount = habitLogsByDate[date]?.first?.count ?? 0
                let habitValue = Double(min(habitCount, habit.targetCount))
                habitValues.append(habitValue)
                moodValues.append(Double(mood.moodScore))
                // Energy tracked for BOTH habit and skip days — enables full Pearson correlation
                if mood.energyScore > 0 {
                    if habitValue >= Double(habit.targetCount) {
                        habitDayEnergyValues.append(Double(mood.energyScore))
                    } else {
                        skipDayEnergyValues.append(Double(mood.energyScore))
                    }
                }
            }

            // CLASS IMBALANCE GUARD: require at least 3 data points in each class
            // (completed days AND skip days). Applies to ALL habits (not just binary) —
            // a multi-count habit completed 13/14 days has the same single-outlier problem.
            // "Completed" = count >= targetCount; "Skipped" = count < targetCount.
            let completedCount = habitValues.filter { $0 >= Double(habit.targetCount) }.count
            let skippedCount = habitValues.filter { $0 < Double(habit.targetCount) }.count
            guard completedCount >= 3, skippedCount >= 3 else { return nil }

            guard let coefficient = pearsonCorrelation(x: habitValues, y: moodValues) else { return nil }

            let target = Double(habit.targetCount)
            let habitDayMoods = zip(habitValues, moodValues).filter { $0.0 >= target }.map { $0.1 }
            let skipDayMoods = zip(habitValues, moodValues).filter { $0.0 < target }.map { $0.1 }
            // habitDayEnergyValues already filtered during loop (energyScore > 0 AND habit completed)

            let strengthLabel: String
            switch abs(coefficient) {
            case 0.5...: strengthLabel = coefficient > 0 ? "Strong positive" : "Strong negative"
            case 0.3..<0.5: strengthLabel = coefficient > 0 ? "Moderate positive" : "Moderate negative"
            case 0.15..<0.3: strengthLabel = coefficient > 0 ? "Mild positive" : "Mild negative"
            default: strengthLabel = "No clear link"
            }

            return CorrelationResult(
                habitID: habit.id,
                habitName: habit.name,
                habitEmoji: habit.emoji,
                coefficient: coefficient,
                averageMoodOnHabitDays: habitDayMoods.isEmpty ? 0 : habitDayMoods.reduce(0, +) / Double(habitDayMoods.count),
                averageMoodOnSkipDays: skipDayMoods.isEmpty ? 0 : skipDayMoods.reduce(0, +) / Double(skipDayMoods.count),
                averageEnergyOnHabitDays: habitDayEnergyValues.isEmpty ? 0 : habitDayEnergyValues.reduce(0, +) / Double(habitDayEnergyValues.count),
                strengthLabel: strengthLabel,
                sampleSize: habitValues.count,
                isBinaryHabit: habit.targetCount == 1,
                isSignificant: false  // set below after Bonferroni correction
            )
        }


        // BONFERRONI CORRECTION: Denominator = total habits that entered the compactMap loop
        // (not raw.count, which excludes habits filtered by class imbalance guard).
        // Rationale: even when a test is skipped due to insufficient data, the *intent* to test
        // inflates familywise error. Using total input habits is the conservative choice.
        let testedCount = habits.count  // Total habits entering loop — correct Bonferroni denominator

        // NOW apply display filter (after capturing denominator)
        let displayFiltered = raw.filter { $0.sampleSize >= minimumPairedDays }  // Safety net — pearsonCorrelation already guards this

        // Apply correction to display-filtered results only
        let correctedAlpha = 0.05 / Double(max(testedCount, 1))
        let results = displayFiltered.map { result in
            var r = result
            r.isSignificant = Self.isSignificant(r: r.coefficient, n: r.sampleSize, alpha: correctedAlpha)
            return r
        }

        return results.sorted { abs($0.coefficient) > abs($1.coefficient) }
        // **Rolling window (v1.0 default: all-time):** Correlations use all available data from Day 14+.
        // In v1.1, add a user-toggleable rolling window (90-day vs all-time) to surface recent
        // behavioral changes rather than averaging over stale historical patterns.
        // Document this as a planned enhancement.
    }

    /// Confidence qualifier for display — low sample sizes need disclaimers
    static func confidenceQualifier(sampleSize: Int) -> String? {
        switch sampleSize {
        case ..<14: return nil  // Suppressed entirely — not enough data
        case 14..<30: return "Based on limited data"  // Show qualifier below correlation card
        case 30..<60: return "Early pattern"
        default: return nil  // n >= 60: high confidence, no qualifier needed
        }
    }

    /// NOTE on statistical method: For binary habits (targetCount == 1), the Pearson correlation
    /// on 0/1 data is equivalent to the point-biserial correlation coefficient. This is mathematically
    /// identical — Pearson applied to dichotomous data IS point-biserial. No separate implementation needed.
    /// The isBinaryHabit flag controls visualization (bar chart vs scatter), not the statistic.
    ///
    /// WHY PEARSON NOT SPEARMAN: On a 1-5 ordinal scale, Pearson and Spearman produce nearly identical
    /// results (see Havlicek & Peterson, 1976). Pearson is faster (no rank sorting) and well-understood.
    /// If v1.1 introduces 10-point scales or non-linear data, switch to Spearman.
    ///
    /// SELECTION BIAS CAVEAT: Users are more likely to log mood on memorable (high/low) days, creating
    /// potential non-response bias. Mitigate via: (1) mood reminder notification encouraging daily logging,
    /// (2) confidence qualifier showing "limited data" for small samples, (3) never claiming causation —
    /// all language uses "on X days, mood averages Y" not "X causes Y".

    // shouldAppear: REMOVED — delegates to DateHelpers.shouldAppear (single source of truth).
    // Both Habit.shouldAppear(on:) and CorrelationEngine call `DateHelpers.shouldAppear(on:frequencyRaw:customDays:)`.
    // See Build Step 1 §12 for the MANDATORY DateHelpers extraction.

    /// Pearson correlation with division-by-zero protection
    /// Uses two-pass algorithm (mean-centered) for numerical stability.
    /// The naive single-pass formula `n*sumXY - sumX*sumY` suffers from catastrophic
    /// cancellation when values are large — mean-centering eliminates this.
    /// All CorrelationEngine and RuleEngine computations MUST use Double (Float64). Never use Float or CGFloat for statistical calculations.
    private static let minimumPairedDays = 14  // Named constant — referenced in pearsonCorrelation guard and outer display filter

    private static func pearsonCorrelation(x: [Double], y: [Double]) -> Double? {
        guard x.count == y.count, x.count >= minimumPairedDays else { return nil }
        let n = Double(x.count)
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        var sumXY: Double = 0, sumX2: Double = 0, sumY2: Double = 0
        for i in x.indices {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }
        // Independent variance check: catch near-degenerate distributions on EITHER axis
        // (e.g., user logs mood as "4" for 29/30 days — sumY2 ≈ 0 but sumX2 is normal)
        guard sumX2 > 1e-6, sumY2 > 1e-6 else { return nil }
        let denominator = sqrt(sumX2 * sumY2)
        guard denominator > 1e-6 else { return nil }  // Epsilon guard: belt-and-suspenders for floating-point edge cases
        return max(-1.0, min(1.0, sumXY / denominator))  // Clamp for floating-point edge cases
    }
}
```

**Present correlations in plain language:** "On exercise days, your mood averages 4.2" — NOT "+0.72 Pearson coefficient."

**Multiple comparisons note:** When displaying correlations for 3+ habits, add a subtle disclaimer below the correlation cards: "We analyzed {N} habits. Some patterns may be coincidental — look for ones that match your experience." This prevents users from making lifestyle changes based on statistical noise from cherry-picked top-3 results.

**Statistical significance (v1.0 — implemented, not deferred):** In addition to sample-size gates (n < 14 suppressed, n < 30 "limited data", n < 60 "early pattern"), compute an approximate p-value for each correlation using the t-statistic:
```swift
/// Significance test for Pearson r using t-distribution approximation.
/// IMPORTANT: The `alpha` parameter is USED — this supports Bonferroni-corrected alpha values.
/// Uses the Abramowitz & Stegun normal approximation for the inverse t-distribution
/// rather than a fixed lookup table, so it works correctly for any alpha value.
static func isSignificant(r: Double, n: Int, alpha: Double = 0.05) -> Bool {
    guard n > 2, abs(r) < 1.0 else { return false }
    let df = Double(n - 2)
    let t = r * sqrt(df / (1.0 - r * r))

    // For small df (12-30), use a precomputed lookup table for alpha=0.05 two-tailed
    // to avoid Cornish-Fisher approximation error (>3% for df<12).
    // For Bonferroni-adjusted alpha values or df>30, use the analytical path below.
    if alpha == 0.05 {
        // t critical values for alpha=0.05 two-tailed (exact from t-distribution tables)
        // Extended table covers df 10-50 for better coverage of typical DailyArc sample sizes
        // (14-365 days of data → df 12-363). For df > 50, Cornish-Fisher is accurate (<0.5% error).
        let exactTable: [Int: Double] = [
            10: 2.228, 11: 2.201, 12: 2.179, 13: 2.160, 14: 2.145, 15: 2.131, 16: 2.120,
            17: 2.110, 18: 2.101, 19: 2.093, 20: 2.086, 22: 2.074, 25: 2.060, 28: 2.048,
            30: 2.042, 35: 2.030, 40: 2.021, 45: 2.014, 50: 2.009
        ]
        let intDf = Int(df)
        if let cv = exactTable[intDf] {
            return abs(t) > cv
        }
        // Interpolate for df between table entries (12-30 range)
        if intDf > 12 && intDf < 30 {
            let keys = exactTable.keys.sorted()
            if let lower = keys.last(where: { $0 <= intDf }),
               let upper = keys.first(where: { $0 > intDf }),
               let cvLower = exactTable[lower], let cvUpper = exactTable[upper] {
                let frac = Double(intDf - lower) / Double(upper - lower)
                let cv = cvLower + frac * (cvUpper - cvLower)
                return abs(t) > cv
            }
        }
    }

    // Analytical path: Abramowitz & Stegun + Cornish-Fisher (accurate for df>30 and any alpha)
    let p = alpha / 2.0  // two-tailed
    let a = sqrt(-2.0 * log(p))
    let zAlpha = a - (2.515517 + 0.802853 * a + 0.010328 * a * a) /
                      (1.0 + 1.432788 * a + 0.189269 * a * a + 0.001308 * a * a * a)
    let g1 = (zAlpha * zAlpha * zAlpha + zAlpha) / (4.0 * df)
    let g2 = (5.0 * zAlpha * zAlpha * zAlpha * zAlpha * zAlpha + 16.0 * zAlpha * zAlpha * zAlpha + 3.0 * zAlpha) / (96.0 * df * df)
    let cv = zAlpha + g1 + g2
    return abs(t) > cv
}
```
Display: correlations where `isSignificant` returns false show a subtle badge: "May be coincidental" in `caption` `textTertiary` below the strength label. **Confidence interval display (premium):** For significant correlations with n ≥ 30, show a 95% CI range below the strength label in `caption2`: "95% CI: [lower, upper]" using Fisher z-transformation: `z = atanh(r)`, `SE = 1/sqrt(n-3)`, `CI = tanh(z ± 1.96*SE)`. This helps data-literate users assess precision without requiring statistics knowledge from casual users (shown below the fold in expanded view only). This prevents users from making lifestyle changes based on noise. For the top-3 displayed correlations, require |coefficient| >= 0.15 AND n >= 14 (display threshold), but significance badge provides additional context. **Multiple comparisons note:** When showing 3+ correlations, the familywise error rate inflates. Apply Bonferroni correction: divide alpha by the number of habits tested (e.g., alpha = 0.05/5 = 0.01 for 5 habits). This is conservative but simple.

**Performance optimization (v1.1+):** For v1.0, the two-pass Pearson implementation is sufficient. For v1.1+ with larger datasets or additional metrics, migrate vector operations to Apple's Accelerate framework (`vDSP_dotpr`, `vDSP_meanv`, `vDSP_measqv`) for 5-10x CPU speedup. This eliminates custom numerical loops and leverages SIMD hardware. For v2.0 with 10+ habits over multi-year data, evaluate Metal compute shaders for parallel correlation of all habit pairs simultaneously.

**Mental health disclaimer at insight delivery (required — Apple Guideline 1.4.1):** Directly below correlation cards in the Insights segment, show in `caption` font with `textTertiary` color: "These are statistical patterns, not medical advice. If you have mental health concerns, please consult a healthcare professional." This disclaimer must appear proximate to health-related content, not only in Settings — Apple reviewers specifically check for this.

---

## Claude Code Build Step Sequence

> Feed these steps in order. Test after each step before proceeding. Each step produces a compilable, runnable app.
>
> **Canonical source of truth:** Code snippets throughout this spec are design-time reference implementations. After Step 1 is implemented, the codebase is the authoritative source of truth. If a bug fix in the codebase diverges from the spec, the codebase wins. Do not update the spec to track code changes — the spec is a design document, not a living mirror of the code.

### Step 1: Data Models, VersionedSchema, StreakEngine, RuleEngine

> **See also:** Data Model spec (line ~300), HabitLogWriteActor (line ~429), Milestone checklist "After Step 1", DailySummary model (line ~5120)

**Step 1 is split into two sub-steps to prevent Week 1 overload:**
- **Step 1a (Week 1):** SwiftData models, schema versioning, `ModelContainer` setup, `DailyArcSchemaV1` with migration plan, `DateHelpers`, `HabitColorPalette`, basic project structure.
- **Step 1b (Week 2):** `StreakEngine`, `DebouncedSave`, `DedupService`, `RuleEngine`, `DebugDataGenerator`, unit tests, performance test baselines.
Each sub-step produces a compilable app.

```
Create a new SwiftUI iOS 17+ app called DailyArc. Set up SwiftData with VersionedSchema:

1. Create VersionedSchema conformance (H2 — explicit shape shown):

   enum DailyArcSchemaV1: VersionedSchema {
       static var versionIdentifier = Schema.Version(1, 0, 0)
       static var models: [any PersistentModel.Type] {
           [Habit.self, HabitLog.self, MoodEntry.self]
       }

       // CRITICAL: All @Model classes MUST be nested inside this enum.
       // SwiftData's VersionedSchema requires models to be defined within the enum scope.
       @Model class Habit { /* ... all properties ... */ }

       @Model class HabitLog { /* ... all properties ... */ }
       #Index<HabitLog>([\.date, \.habitIDDenormalized])

       @Model class MoodEntry { /* ... all properties ... */ }
       #Index<MoodEntry>([\.date])
       // #Index macros MUST be placed immediately after the @Model class, inside the VersionedSchema enum scope.
   }

   // Convenience type aliases at module scope
   typealias Habit = DailyArcSchemaV1.Habit
   typealias HabitLog = DailyArcSchemaV1.HabitLog
   typealias MoodEntry = DailyArcSchemaV1.MoodEntry

   enum DailyArcMigrationPlan: SchemaMigrationPlan {
       static var schemas: [any VersionedSchema.Type] { [DailyArcSchemaV1.self] }
       static var stages: [MigrationStage] { [] } // Empty for v1, add stages in v1.1
   }

   // **Migration Playbook (for v1.1+):**
   // - NEVER modify DailyArcSchemaV1 models after v1.0 ships. All changes go into DailyArcSchemaV2.
   // - Adding optional properties: use SchemaV2 with lightweight migration (SwiftData handles automatically).
   // - Adding non-optional properties: use `MigrationStage.custom` with default value population.
   // - Renaming/removing properties: use `MigrationStage.custom` with explicit data transformation.
   // - NOTE: `energyScore == 0` is a sentinel value — any v2 migration touching MoodEntry must preserve this semantics.
   // - NOTE: `isCOPPABlocked` in Keychain is a compliance flag — migrations must never clear Keychain keys.

2. HabitFrequency enum (separate file or alongside Habit):
   enum HabitFrequency: Int, Codable, CaseIterable {
       case daily = 0, weekdays = 1, weekends = 2, custom = 3
   }

3. Habit @Model: id (UUID), name (String), emoji (String), colorIndex (Int, default 5 — Sky), frequencyRaw (Int, backed by HabitFrequency enum), customDays (String, pipe-delimited "0|2|4"), targetCount (Int, default 1), reminderTime (Date?), reminderEnabled (Bool, false), healthKitTypeRaw (String?), autoLogHealth (Bool, false), startDate (Date), isArchived (Bool, false), sortOrder (Int), currentStreak (Int, 0), bestStreak (Int, 0), createdAt (Date). @Relationship(deleteRule: .cascade) var logs: [HabitLog].

   Computed: frequency (HabitFrequency get/set), color (Color from hex), customDayIndices ([Int] from pipe string), shouldAppear(on: Date) -> Bool.

4. HabitLog @Model: id (UUID), date (Date), count (Int), notes (String, default ""), isAutoLogged (Bool, false), isRecovered (Bool, false), **habitIDDenormalized (UUID)** — stored copy of `habit?.id` for indexed queries without relationship faults, createdAt (Date). var habit: Habit? back-reference. Index with #Index<HabitLog>([\.date, \.habitIDDenormalized]) (iOS 17.4+ is our minimum). **CRITICAL:** `habitIDDenormalized` MUST be set on every HabitLog creation — in `fetchOrCreate`, in `HabitLogWriteActor.saveLog`, and in `applyRecovery`. It is used by CorrelationEngine.extractSnapshots, DedupService, and the compound index.

   CRITICAL: Add static fetchOrCreate(habit:date:context:) -> HabitLog upsert method. Query by habit + normalized date first. Update if found, create if not. This prevents duplicate logs on rapid tapping.

5. MoodEntry @Model: id (UUID), date (Date), moodScore (Int, 1-5), energyScore (Int, 1-5, **default 0 = sentinel "not logged"** — distinct from score 1 which means "Low"), activities (String, pipe-delimited, default ""), notes (String, default ""), createdAt (Date). Index date. Computed: activityList, moodEmoji. **energyScore sentinel:** 0 means user has not yet logged energy for this entry. UI shows energy picker in unselected state when energyScore == 0. CorrelationEngine and RuleEngine MUST filter out entries where energyScore == 0 from energy-related analysis (same pattern as moodScore sentinel).

   CRITICAL: Add static fetchOrCreate(date:context:) -> MoodEntry upsert method. Same pattern as HabitLog: query by normalized date first, update if found, create if not. DedupService (see below) also covers MoodEntry — if two entries exist for the same date (e.g., from rapid-tap race), keep the one with the later `createdAt` timestamp.

6. DaySnapshot as plain struct (NOT @Model).

7. PersistenceController: configure ModelContainer with DailyArcMigrationPlan.
   **NOTE (v30): With HabitLogWriteActor as the single write path, there is no dual-context race.**
   The main context is read-only for HabitLog/MoodEntry. HabitLogWriteActor owns all writes.
   ```swift
   let container = try ModelContainer(
       for: [DailyArcSchemaV1.Habit.self, DailyArcSchemaV1.HabitLog.self, DailyArcSchemaV1.MoodEntry.self, DailyArcSchemaV1.DailySummary.self],
       migrationPlan: DailyArcMigrationPlan.self,
       configurations: ModelConfiguration(
           // Merge policy: store wins on conflict (HealthKit writes are idempotent via max(count))
           // This ensures the most recent save always wins, which is safe because:
           // - HabitLogWriteActor uses max(log.count, newCount) so data only goes up
           // - DebouncedSave coalesces main-actor writes so conflicts are rare
       )
   )
   // Note: As of iOS 17, SwiftData's ModelContainer does not expose NSMergePolicy directly.
   // The default behavior is "last writer wins" which is acceptable for our use case.
   // **v30 NOTE:** HabitLogWriteActor consolidates all writes — the dual-context escape hatch
   // is no longer needed. DedupService is retained as defense-in-depth only. Monitor
   // dedup_correction_count — it should be ~0 with the single-writer architecture.
   ```
   **CRITICAL — add immediately after container creation in DailyArcApp.swift:**
   ```swift
   container.mainContext.autosaveEnabled = false
   ```
   SwiftData defaults autosave to `true`, which triggers saves outside the DebouncedSave flow,
   conflicting with the explicit save strategy and causing unexpected write patterns.
   This MUST be set before any view body is evaluated — do it in the `App.init()` or `WindowGroup`'s
   `.modelContainer()` modifier's closure.

**ModelContainer failure recovery:** If `ModelContainer` creation throws (e.g., corrupt store on disk), present a user-facing alert with TWO options: (1) **"Try to Repair"** — attempts to delete the existing store file at `URL.applicationSupportDirectory` and recreate the container (may recover if corruption is minor), (2) **"Reset App"** — wipes all data and starts fresh. Do NOT silently delete user data — the user must choose. If repair also fails, fall through to the Reset option. Log the failure details (error code, store size) to MetricKit. This is a fatal error path — the app cannot function without a ModelContext.

8. StreakEngine: recalculateStreaks(for:logs:) — caller passes pre-fetched [HabitLog] (avoids habit.logs relationship fault). Starts from yesterday if today not completed — fixes morning off-by-one, includes isRecovered logs in streak count. computeBestStreak (full recompute, not just ratchet up), streakRecoveryAvailable, applyRecovery (marks logs isRecovered=true, re-fetches logs after mutation). IMPORTANT: StreakEngine does NOT call context.save() — the caller's DebouncedSave handles persistence.

9. RuleEngine (Services/ ONLY — caseless `enum` with static methods, NOT `@MainActor class`): `generateSuggestions` with 12 rules. completionRate divides by applicable days (not logged days). Excludes isRecovered logs. Extract Sendable snapshots on @MainActor, compute via Task.detached, return [Suggestion] (Sendable struct). Guard: `applicableDays >= 7` (not `monthLogs.count >= 7`) before showing completion rate suggestions. Uses `DateHelpers.shouldAppear` (not a local duplicate). **Performance:** Use `Dictionary(grouping: logs, by: \.habitID)` to pre-group logs by habit ID in a single O(L) pass, then iterate habits in O(H) — total O(L+H) instead of O(H*L) filter-per-habit pattern. Same approach as CorrelationEngine.

10. Constants: habitColors (10 with light/dark hex), maxFreeHabits (3), streakMilestones, journalingPrompts (20+). `stableUserID` (UUID) is lazily generated on first need and stored in Keychain — used for feature flag bucketing (FeatureFlag), share card attribution (`ct` parameter), and v1.1 referral system. Access via `KeychainService.stableUserID` (lazy getter that generates on first access). **Do NOT generate at first launch unconditionally** — see TTDSG Section 25 compliance note in FeatureFlag section.

11. Color extension: `init(hex:)` → Color, plus `init(light:dark:)` convenience initializer using `UIColor` dynamic provider: `Color(UIColor { traits in traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })`. **Do NOT use `UITraitCollection.current.userInterfaceStyle`** — deprecated in iOS 17 and logs warnings. The dynamic provider pattern properly responds to trait changes. This powers all adaptive tokens in `DailyArcTokens`.

12. DateHelpers, HapticManager, DebouncedSave (300ms coalescing wrapper).
    **MANDATORY: DateHelpers.swift must contain a single `shouldAppear(on:frequencyRaw:customDays:calendar:)` free function.**
    ```swift
    enum DateHelpers {
        /// Single source of truth for habit-day applicability.
        /// `calendar` parameter REQUIRED — prevents Calendar.current access in non-main contexts.
        static func shouldAppear(on date: Date, frequencyRaw: Int, customDays: String, calendar: Calendar) -> Bool {
            let weekday = calendar.component(.weekday, from: date) // 1=Sun, 7=Sat
            let dayIndex = weekday - 1 // 0=Sun, 6=Sat
            guard let frequency = HabitFrequency(rawValue: frequencyRaw) else { return true }
            switch frequency {
            case .daily: return true
            case .weekdays: return (1...5).contains(dayIndex) // Mon-Fri
            case .weekends: return dayIndex == 0 || dayIndex == 6
            case .custom:
                let indices = customDays.split(separator: "|").compactMap { Int($0) }
                return indices.contains(dayIndex)
            }
        }
    }
    ```
    Both `Habit.shouldAppear(on:calendar:)` and `CorrelationEngine` MUST delegate to this shared function.
    Do NOT duplicate the weekday logic — divergence between these two implementations will silently corrupt correlation data.
    Add a unit test in Step 1 asserting equivalence for all 7 weekdays × all 4 frequency types.

13. PaywallStubView placeholder.

14. DebugDataGenerator: Creates 365 days of synthetic habit logs, mood entries, and streak scenarios for testing heat maps, correlations, and milestones.

15. XCTest targets: StreakEngineTests, RuleEngineTests, FetchOrCreateTests, PerformanceTests.

16. **PerformanceTests target** (automated regression tests using `XCTest.measure {}`):
    ```swift
    final class PerformanceTests: XCTestCase {
        let generator = DebugDataGenerator()  // 365 days, 10 habits

        func testCorrelationEnginePerformance() {
            let snapshots = generator.makeHabitSnapshots(count: 10, days: 365)
            let moods = generator.makeMoodSnapshots(days: 365)
            measure {
                _ = CorrelationEngine.computeCorrelations(habits: snapshots, moods: moods, calendar: .current)
            }
            // Baseline: <500ms on iPhone XS (A12). CI runs on Mac — set baseline accordingly.
        }

        func testStreakEnginePerformance() {
            let logs = generator.makeLogSnapshots(days: 365)
            measure {
                _ = StreakEngine.computeBestStreak(logs: logs, calendar: .current)
            }
            // Baseline: <10ms per habit
        }

        func testDedupServicePerformance() {
            let context = generator.makeModelContext(duplicates: 50)
            measure {
                DedupService.runIfNeeded(context: context)
            }
            // Baseline: <200ms for 2,500 entries with 50 duplicates
        }

        func testHeatMapRenderPerformance() {
            let data = generator.makeHeatMapData(days: 365)
            measure {
                _ = HeatMapCanvas.render(data: data, size: CGSize(width: 350, height: 200))
            }
            // Baseline: <100ms for 365-cell Canvas render
        }
    }
    ```
    Run on every CI build. Set baselines per machine (Mac CI ≠ device). Alert on >20% regression. These tests use `DebugDataGenerator` for deterministic synthetic data.

Test: Models compile with VersionedSchema, StreakEngine handles morning off-by-one correctly, fetchOrCreate prevents duplicates, RuleEngine uses applicable-day rates, Color(hex:) works in both color schemes, DebugDataGenerator populates test data. **Schema fingerprint test:** assert that `VersionedSchemaV1` property list (sorted model names + sorted property names per model) matches a committed snapshot — any schema change forces conscious migration plan update.
```

### Step 2: Today View — Decoupled Mood + Auto-Save Habits

> **See also:** Screen 2 spec (line ~1195), DebouncedSave (line ~2265), Whimsy Day 1-25 touchpoints (line ~1788), Milestone checklist "After Step 2"

```
Build the Today View dashboard for DailyArc. CRITICAL ARCHITECTURE: @Query lives in Views for static data. Dynamic date filtering uses ModelContext.fetch.

1. TodayView.swift:
   - @Query for all non-archived Habits (static — doesn't change with date): @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \.sortOrder)
   - @State var selectedDate: Date = Calendar.current.startOfDay(for: Date())
   - @State var viewModel = TodayViewModel()  // MUST be @Observable class
   - @Environment(\.modelContext) private var context

   CRITICAL (B1): @Query predicates are compile-time constants. You CANNOT bind them to @State selectedDate.
   For date-dependent data (HabitLogs, MoodEntry), use ModelContext.fetch:

   .onChange(of: selectedDate) { _, newDate in
       viewModel.fetchLogsForDate(newDate, context: context)
   }
   .onAppear {
       viewModel.fetchLogsForDate(selectedDate, context: context)
   }

2. TodayViewModel — MUST be @Observable AND @MainActor (B2, Swift 6 safety):
   @MainActor @Observable
   class TodayViewModel {
       var habitLogs: [HabitLog] = []
       var moodEntry: MoodEntry? = nil

       /// nonisolated init allows @State initialization without @MainActor context.
       /// Required for Swift 6 strict concurrency: @State var viewModel = TodayViewModel()
       /// would fail compilation without this because @State.init is nonisolated.
       nonisolated init() {}

       func fetchLogsForDate(_ date: Date, context: ModelContext) {
           let normalized = Calendar.current.startOfDay(for: date)
           let logDescriptor = FetchDescriptor<HabitLog>(
               predicate: #Predicate { $0.date == normalized }
           )
           habitLogs = (try? context.fetch(logDescriptor)) ?? []

           let moodDescriptor = FetchDescriptor<MoodEntry>(
               predicate: #Predicate { $0.date == normalized }
           )
           moodEntry = try? context.fetch(moodDescriptor).first
       }
   }

2. DateNavigationBar at top:
   - Left "<" and right ">" arrows to change selectedDate by ±1 day
   - Center: "Today" / "Yesterday" / formatted date. **Long-press center label → calendar picker** (`.datePickerStyle(.graphical)`, sheet presentation) for quick backfill navigation to any past date. Dismiss on date selection.
   - Right arrow disabled when selectedDate == today
   - **Transition animation:** Content slides left/right matching arrow direction (`.transition(.move(edge: .leading))` for backward, `.move(edge: .trailing)` for forward). Duration: 0.25s ease-in-out. Reduce motion: instant swap, no slide.
   - Allows backfilling missed days

3. Mood Check-In Section (INDEPENDENT from habits):
   - Card with "How are you feeling?" prompt if no mood logged for selectedDate
   - 5 emoji circles (60pt): 😔 😕 😐 🙂 😄
   - Selected has accent ring (4pt stroke)
   - AUTO-SAVE on tap: use MoodEntry.fetchOrCreate(date:context:) then update moodScore + debounced save (300ms)
   - Show 3-second undo toast after save. **Accessibility:** Undo toast MUST have `.accessibilityAddTraits(.isButton)` and announce via `AccessibilityNotification.Announcement` when it appears. Auto-dismiss pauses while VoiceOver focus is on the toast (use `AccessibilityEnvironment.isVoiceOverRunning` check). If VoiceOver is active, extend dismiss timer to 6 seconds and add an explicit "Dismiss" button.
   - After mood selected, reveal:
     * Energy picker: 5 tappable circles (44pt diameter, accent ring on selected, labeled 1-5 with "Low"/"High" endpoints, header: "Energy" — arc metaphor reserved for trajectories/growth arcs, not point-in-time measurements) — matching mood picker pattern for consistency. Auto-saves on tap via fetchOrCreate + debounced save. Ring stroke: 3pt (differentiated from mood's 4pt). Inter-circle spacing: 12pt.
     * Activity tags (horizontal scroll): 👥 Social, 🏃 Exercise, 💼 Work, 🎨 Creative, 🎵 Music, 📚 Reading, 🧘 Mindful, 😴 Rest. Multi-select, auto-save on toggle. "+" for custom tag.
     * Notes TextField with rotating journaling prompt placeholder — auto-saves on .onSubmit or focus loss

4. Streak Recovery Banner (conditional):
   - Show if StreakEngine.streakRecoveryAvailable returns true for any habit
   - Warning card: background `DailyArcTokens.warning` at 15% opacity, border `DailyArcTokens.warning` at 1pt, corner radius 12pt
   - Left: ⚡ emoji (24pt). Center: "{emoji} {name}: missed 1 day? Tap to keep your streak!" in `bodyLarge`
   - "Restore" button (accent, capsule shape, 36pt height) calls StreakEngine.applyRecovery
   - Dismiss "✕" (top-right, `textTertiary`, 44pt tap target) hides for this session (@State flag)
   - **Error state:** If recovery fails (transaction error), show inline red text below button: "Couldn't restore — tap to try again" with retry action. Banner stays visible until dismissed or recovered.

5. Habit List Section:
   - Header: "Habits" + count badge "{done}/{total}" + "+" button (→ HabitFormView) + "Manage" link (→ HabitManagementView)
   - Filter habits by selectedDate using habit.shouldAppear(on:)
   - Each HabitRowView:
     * Emoji (40pt) + name
     * CompletionCircleView (hollow → filled % based on count/targetCount)
     * Streak badge "🔥 {currentStreak}" (hidden if 0)
     * targetCount == 1: tap row to toggle. AUTO-SAVE via HabitLog.fetchOrCreate(habit:date:context:) + debounced save (300ms). Show 3-sec undo toast.
     * targetCount > 1: stepper "−" / count / "+" (min 0, max targetCount). AUTO-SAVE via fetchOrCreate + debounced save.
     * Swipe left: "Edit" (→ HabitFormView edit mode), "Archive" (set isArchived=true)
   - When count reaches targetCount: checkmark animation + haptic .success
   - When ALL habits complete: CelebrationOverlay (confetti, 2 sec) + haptic .success

6. Streak milestone check: after habit completion, if currentStreak matches a milestone (3/7/14/30/60/100/365), show milestone toast with badge.

7. Time-of-day greeting above mood section: "Good morning, {name}!" etc.

8. Empty state: EmptyStateView "No habits yet" + "Create Your First Habit" button
9. Loading state: skeleton placeholder
10. Error state: "Something went wrong" + retry

11. Accessibility: every emoji has accessibilityLabel ("Mood: great, 5 out of 5"), habit rows have accessibilityValue ("Exercise, 2 of 3 completed, streak 12 days"), stepper buttons have accessibilityHint.

Test: Habits filter by day, tap toggles completion and saves immediately, mood saves independently, date navigation works, streaks update, confetti fires on all-complete.
```

### Step 3: Habit Form (Add/Edit), Templates, Habit Management

> **See also:** Screen 3 spec (line ~1320), Screen 4 spec (line ~1380), Free vs Premium tier table, Milestone checklist "After Step 3"

```
Build the Habit creation and management system for DailyArc:

1. HabitFormView — shared for Add and Edit modes:
   - @State var mode: FormMode (.add / .edit(Habit))
   - Template Quick-Start (Add mode only): horizontal scroll of 8 templates (🏃 Exercise, 📚 Reading, 🧘 Meditate, 💤 Sleep 8hrs, 💧 Drink Water, 📝 Journal, 🚶 Walk, 🎨 Creative Time). Tap → pre-fills emoji, name, frequency=daily, targetCount=1.
   - "Or create custom" divider below templates.

   Step 1 — Details & Schedule:
   - EmojiPickerView: grid (8 columns × 6 rows). Tap selects, accent ring.
   - Color picker: 10 swatches from Constants.habitColors. Tap selects, checkmark.
   - Name TextField (placeholder "e.g., Exercise", required validation)
   - Frequency SegmentedControl: Daily(0) / Weekdays(1) / Weekends(2) / Custom(3)
   - If Custom(3): 7 toggle buttons Sun–Sat. Must select ≥1. Display "Selected: Mon, Wed, Fri".
   - Target stepper (1–10, default 1). Label: "Times per day"
   - "Next" button (disabled if name empty or custom with no days)

   Step 2 — Reminders & Health:
   - Reminder toggle. If enabled: DatePicker (.compact, default 9 AM).
   - On FIRST reminder toggle ON: request UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]). If denied, show inline warning.
   - **Soft-ask pattern (onboarding Page 3):** Before firing the system permission dialog, show a custom pre-permission screen: "Get gentle reminders to keep your streak alive" with "Enable Reminders" (accent button) and "Not now" (text link). Only fire `requestAuthorization` if user taps "Enable Reminders." This lifts opt-in rates from ~50% to 70%+. Users who tap "Not now" can enable later in Settings.
   - HealthKit section: "Auto-log from Health" toggle.
   - If enabled: picker for metric ("Workouts", "Steps >5000", "Sleep >7hrs", "Mindful Minutes").
   - On toggle ON: request HealthKit authorization for selected type.
   - "Save Habit" button.

   On save (Add):
   - Create Habit with sortOrder = max(existingHabits.sortOrder) + 1
   - If HealthKit: fetch 30-day backfill via HKStatisticsCollectionQuery, create HabitLogs with isAutoLogged=true
   - Register HKObserverQuery for ongoing updates
   - Recalculate streaks
   - Toast: "{emoji} {name} created!"
   - Dismiss

   On save (Edit):
   - Update properties. If frequency changed, recalculate streaks.
   - Toast: "{emoji} {name} updated!"
   - Dismiss

   Validation: name non-empty (trim whitespace), custom freq ≥1 day, duplicate name warning (non-blocking).

   FREE TIER GUARD: In Add mode, if user has 3 active (non-archived) habits, show PaywallStubView instead of form.

2. HabitManagementView:
   - Reorderable List with drag handles (EditMode)
   - Each row: emoji + name + streak badge + active/archived indicator
   - Swipe: Edit (→ HabitFormView edit), Archive (sets isArchived=true), Delete (destructive confirm, permanently removes Habit + cascades logs)
   - "Show Archived" toggle at bottom: reveals grayed archived habits with "Unarchive" swipe
   - "Add Habit" button (free tier guard)
   - On reorder: update sortOrder values

3. HabitTemplatesView (used in onboarding and form):
   - Static array of 8 template habits with emoji, name, frequency, targetCount
   - Each rendered as tappable card
   - Returns selected template data to parent

4. EmojiPickerView: 8×6 grid of common habit emojis, search not needed for v1

5. Accessibility: form fields have accessibilityLabel, frequency picker announces selection, stepper has accessibilityHint, drag handle has accessibilityLabel "Reorder".

Test: Add habit with template, add custom habit, edit existing habit, reorder, archive/unarchive, free tier limit enforced at 3.
```

### Step 4: Stats View, Canvas Heat Map, Mood Trend Chart

> **See also:** Screen 5 spec (line ~1394), Heat map spec (line ~1400), Performance targets for heat map (<100ms), Milestone checklist "After Step 4", MVP Decision Gate

```
Build the Stats view with heat map and charts for DailyArc:

1. StatsView.swift — uses ModelContext.fetch for progressive loading (NOT @Query, which eagerly loads everything):
   - @Query for all non-archived Habits ONLY (lightweight, always needed)
   - HabitLogs and MoodEntries loaded via ModelContext.fetch(FetchDescriptor) for progressive loading:
     * On appear: fetch last 30 days of logs + moods (fast, covers mood chart + per-habit cards)
     * In background Task: fetch full 365 days for heat map computation
     * This prevents loading a year of data before the view even renders
   - Segmented control at top: "Your Arc" | "Insights" (Insights shows teaser card for free users — NOT blurred)
   - @State var viewModel = StatsViewModel()
   - Pass fetched data to viewModel

2. Overview Segment:

   HeatMapCanvasView — Canvas-rendered (NOT 365 SwiftUI views):
   - Use Canvas { context, size in ... } to draw 52 columns × 7 rows of colored rectangles
   - Batch-compute DaySnapshots for past year using viewModel.snapshots() (single query + in-memory grouping)
   - Color scale: **Use the Sky-to-Indigo brand gradient defined in Screen 5 (lines 949-955). Do NOT use green.** systemGray6 (no data), systemGray5 (0%), light sky `#B3D9F2`/dark `#2A5F8A` (1-25%), medium blue `#6BA3D6`/dark `#3D7AB8` (26-75%), deep indigo `#3A5BA0`/dark `#7B9FE0` (76-100%). Add 1pt border using `borderThin` token per Screen 5 WCAG note.
   - Month labels on top via overlay Text views
   - Tap gesture: use coordinate math to find tapped cell, update fixed detail bar below with date + % + mood emoji
   - Horizontal ScrollView
   - Empty state: "Start logging to fill your calendar" with faded preview

   MoodTrendView — Swift Charts LineMark:
   - Last 30 days of MoodEntries
   - X-axis: date (label every 7 days)
   - Y-axis: mood 1-5 with emoji labels
   - Line color: accent. Optional dashed energy overlay.
   - Tap → tooltip: date + mood emoji + energy
   - Empty state (<3 entries): "Log your mood for 3+ days to see trends"

   Per-Habit Cards — LazyVGrid 2 columns:
   - Each card: emoji + name + "🔥 {currentStreak}" + "Best: {bestStreak}" + completion rate ring + sparkline
   - Reads from cached habit.currentStreak and habit.bestStreak (no recalculation)
   - Tap → PerHabitDetailView
   - Empty state: "Create habits to see stats"

3. PerHabitDetailView (drill-down):
   - Header: emoji + name + "Edit" button
   - Total completions (lifetime)
   - Current streak + start date
   - Best streak + date range
   - This month bar chart (daily completion)
   - Last 12 months bar chart (monthly %)
   - "Archive" button (orange, confirm)
   - "Delete Habit" button (red, destructive confirm: "This permanently deletes all data.")

4. StatsViewModel (MUST be @Observable):
   @MainActor @Observable class StatsViewModel {
       nonisolated init() {}  // Required for @State initialization in Swift 6
       // ... properties and methods ...
   }
   - snapshots(habits:, logs:, moods:, from:, to:) -> [DaySnapshot]: batch-compute using single-query + in-memory grouping
   - moodTrendData(moods:, days:) -> [(date: Date, moodScore: Int, energyScore: Int)]
   - Per-habit stats read directly from cached streak values on Habit model
   - Progressive loading: load last 30 days on appear, then load full 365 days in Task { } background. Store Task handle in @State var fullYearTask: Task<Void, Never>? — cancel in .onDisappear to avoid wasted work when user navigates away. Show loading indicator for heat map during full-year computation.

5. Accessibility:
   - Heat map: group cells by week as `accessibilityElement(children: .combine)` containers. Each week announces "Week of March 3: average 75% completion." Add `accessibilityChartDescriptor` for the heat map (consistent with mood chart). Provide rotor action to jump between months. Individual cell taps update the detail bar which becomes the accessibility focus target.
   - Chart points accessible via `accessibilityChartDescriptor`. Cards announce streak values. All chart axes labeled.

6. **Correlation result caching:** StatsViewModel (or a dedicated CorrelationCache) stores the most recent `[CorrelationResult]` in a `@State` property. Invalidation triggers: (a) new HabitLog saved (observed via DebouncedSave completion callback), (b) new MoodEntry saved, (c) date change (midnight), **(d) TTL of 24 hours** — if the cache is older than 24h (tracked via `cacheTimestamp: Date`), force recomputation even if no explicit invalidation occurred (safety net for backgrounded-then-resumed scenarios where no new data was logged). On Insights segment appear, check if cache is valid (data hasn't changed since last computation AND within TTL). If valid, display cached results immediately — no recomputation. If invalid, recompute in `Task.detached` (passing `calendar` captured on @MainActor) and update cache on completion. On memory pressure, release the cache (results will recompute on next view appearance). This prevents redundant O(H*M) recomputation on every tab switch.

Test: Heat map renders 365 days with correct colors, mood chart shows trend line, per-habit cards display cached streaks, drill-down shows detailed stats, empty states render.
```

### Step 5a: StoreKit 2, Paywall (split from original Step 5)

> **See also:** Screen 7 Paywall spec (line ~1570), Free vs Premium tier table, Milestone checklist "After Step 5a"

```
Build StoreKit integration and paywall for DailyArc:

1. Insights Segment placeholder (in StatsView, premium-gated):
   - If not premium: show teaser card with one sample insight + "See all insights" upgrade button → PaywallView (NOT blurred — teaser signals value, blur signals distrust)
   - If premium: placeholder "Insights coming in Step 5b"
   - Full Insights UI (CorrelationCardView, SuggestionCardView, Activity Insights) built in Step 5b

2. StoreKitManager (StoreKit 2):
   - Product ID: "com.dailyarc.premium" (non-consumable, $5.99)
   - On init: await Product.products(for: ["com.dailyarc.premium"])
   - purchase() async: product.purchase() → verify → finish transaction
   - isPremium computed: check Transaction.currentEntitlements
   - Cache in @AppStorage("isPremium") — but this is CACHE only, verify on launch
   - restorePurchases() async
   - Listen for Transaction.updates in background Task
   - Purchase states: idle → loading → success → error (with error message + retry)
   - Family Sharing enabled in App Store Connect

3. PaywallView (replace PaywallStubView):
   - Icon (80pt), "See what makes you happier" (28pt bold) — leads with emotional value, not feature unlock
   - "One payment. Yours forever." subtitle
   - "Your insights. Your device. Your price." (gray 16pt) — reinforces privacy differentiator
   - Feature list with SF Symbol checkmarks:
     ✓ Unlimited habits (free: up to 3)
     ✓ Mood-habit correlation insights
     ✓ Full smart suggestions (12+ rules)
     ✓ Detailed trend analysis
     ✓ CSV export & data import (note: basic JSON export is always free — do NOT list it as premium)
     ✓ Home screen widgets (medium & large)
   - product.displayPrice + " one-time" (32pt bold accent) — NEVER hardcode price
   - "No subscriptions. No recurring charges." (gray 14pt)
   - DO NOT mention competitor names
   - Purchase button: full width, 50pt, accent color
   - States: idle → loading spinner → success checkmark → error with retry
   - "Restore Purchases" link
   - "Not now" dismiss link → warm acknowledgment toast: "No worries — DailyArc is great free too."

4. Update all premium gates throughout app:
   - Insights segment in StatsView
   - RuleEngine: pass isPremium to control rule set
   - Habit creation: enforce 3-habit limit for free
   - Basic JSON export: FREE (GDPR). CSV export + import: premium only.
   - Medium/large widgets: premium only (check in widget timeline provider)
   - StoreKit optimistic loading: default to @AppStorage("isPremium") cache so premium users don't briefly see free tier

Test: Premium purchase in sandbox, paywall displays with product.displayPrice, premium gates work, free tier limits enforced, JSON export works for free users.
```

### Step 5b: Insights, Correlation Engine (split from original Step 5)

> **See also:** CorrelationEngine spec (line ~2560), DPIA blocking prerequisite (Pre-Launch Checklist Phase 2), Milestone checklist "After Step 5b", Risk Register "GDPR complaint" entry, Technical Debt #7 (threshold tuning)

```
Build the premium Insights features for DailyArc (replaces placeholder from Step 5a):

1. Insights Segment (in StatsView, premium-gated):
   - If not premium: show teaser card with one sample insight + "See all insights" upgrade button (NOT blurred view)
   - If premium: show all insight cards
   - Loading state: show spinner while CorrelationEngine computes (runs async)

   CorrelationCardView:
   - Uses CorrelationEngine.computeCorrelations()
   - Minimum 14 days of paired data. If insufficient: "Keep logging for {remaining} more days to unlock insights."
   - Top 3 results displayed in plain language:
     * "🏃 Exercise → mood averages 4.2 on exercise days" (NOT raw coefficient)
     * Subtext: strength label + confidence qualifier (see confidenceQualifier rules)
     * Color: `DailyArcTokens.success` (positive, coefficient > 0.15), `DailyArcTokens.textSecondary` / gray (no clear link, abs < 0.15), `DailyArcTokens.error` (negative, coefficient < -0.15). **Must match canonical definition in Screen 5.**
   - Tap to expand: scatter plot (Swift Charts PointMark) with habit count (X) vs mood (Y)

   SuggestionCardView:
   - Premium: all 12+ RuleEngine suggestions
   - "Refresh" button regenerates

   Activity Insights (premium):
   - Activities on high-mood days (moodScore >= 4)
   - Chip grid with counts: "👥 Social: 8x"
   - Empty state: "Tag activities when logging mood to see patterns"

2. CorrelationEngine (Services/CorrelationEngine.swift):
   - computeCorrelations is ASYNC — call via Task.detached { } (NOT Task { } which inherits @MainActor and blocks UI)
   - Filters by habit.shouldAppear(on:) — weekends don't pollute weekday habits
   - Excludes isRecovered logs from calculations
   - Lowered thresholds: 0.5+ strong, 0.3-0.5 moderate, 0.15-0.3 mild (behavioral science norms for ordinal/binary data)
   - Returns isBinaryHabit flag for visualization selection
   - Includes averageEnergyOnHabitDays to surface energy data meaningfully

3. Visualization per habit type:
   - Binary habits (targetCount == 1): side-by-side bar chart "Mood on exercise days vs skip days"
   - Multi-count habits: scatter plot (PointMark)
   - All correlations: plain language display "On exercise days, mood averages 4.2"

4. Activity Insights, SuggestionCardView (premium: all 12+ rules)

5. CorrelationEngineTests: test with known data, verify threshold labels, verify shouldAppear filtering

Test: Correlation runs async with loading state, results display in plain language, binary habits show bar chart, thresholds produce meaningful labels, excluded recovered logs.
```

### Step 6: Settings, Notifications, Data Export

> **See also:** Screen 6 Settings spec (line ~1430), GDPR consent flow (line ~1460), Notification copy in RuleEngine (line ~1915), Brand Voice Matrix, Privacy Policy template (line ~4660), Milestone checklist "After Step 6"

**Step 6 is split into two sub-steps:**
- **Step 6a (Week 8):** Settings screen (appearance, notification toggles, about section, in-app help system), JSON/CSV export with DTO structs.
- **Step 6b (Week 9):** GDPR consent flow, COPPA age gate with Keychain, consent withdrawal UI, notification scheduling with copy variants.
Each sub-step is independently shippable.

```
Build Settings, notifications, and data management for DailyArc:

1. SettingsView with Form sections:

   Profile: display name (@AppStorage("userName")), accent color picker (10 swatches)

   Notifications & Reminders:
   - Master toggle
   - "Evening reminder" toggle + time picker (default 8 PM)
   - "Streak check-in" toggle (morning-after, 9 AM default)
   - "Mood reminder" toggle + time picker (default 9 PM)
   - ON FIRST TOGGLE: request UNUserNotificationCenter.requestAuthorization
   - If denied: inline warning + "Open Settings" link (UIApplication.openSettingsURLString)

   Data Management (IMPORTANT: this entire section is ALWAYS visible to ALL users — never behind a paywall gate):
   - "Export JSON" (**FREE** — GDPR Article 20 right to portability) → ShareLink. Uses DTO structs, runs on Task.detached with progress indicator. Must be reachable without premium purchase.
   - "Export CSV" (premium — show lock icon + "Upgrade" if free) → ShareLink
   - "Import JSON" (premium — show lock icon + "Upgrade" if free) → file picker, merge/overwrite dialog
   - "Delete All My Data" → red button, type "DELETE" to confirm (GDPR Article 17 — Right to Erasure). Deletes: all SwiftData stores (habits, logs, mood entries), all `UserDefaults.standard` keys (onboarding flags, preferences), all `UserDefaults(suiteName: "group.com.dailyarc.shared")` keys (widget JSON), `@AppStorage("allRecoveryDates")` JSON blob, **Keychain keys** (`dobMonth`, `dobYear`, `isCOPPABlocked`, `stableUserID`), and resets to first-launch state. Calls `WidgetCenter.shared.reloadAllTimelines()` to blank widgets. Shows confirmation: "This permanently deletes all your data. This cannot be undone."

   Health & Privacy:
   - HealthKit status badge
   - "Manage Health Metrics" → list of synced types
   - **"Withdraw Processing Consent" toggle (GDPR Art. 7(3)):** When toggled OFF, the app ceases all processing (mood-habit correlations disabled, analytics stopped, HealthKit sync paused). Shows degraded state explaining what functionality is lost: "Some features require data processing consent. Re-enable anytime." Withdrawal must be "as easy as" giving consent (same number of taps as the original onboarding toggle). This is the in-app UI for the consent withdrawal flow defined in Settings → Health & Privacy. Distinct from "Delete All My Data" — withdrawal stops processing but retains data on-device until explicitly deleted.
   - **"Do Not Sell or Share My Personal Information" link (CCPA Cal. Civ. Code 1798.135):** Navigates to a screen confirming: "DailyArc does not sell or share your personal information with third parties. Your data stays on your device." Even though no selling occurs, this link is required for California compliance and costs nothing to implement.
   - "Anonymous Analytics" toggle (default OFF — requires affirmative opt-in for GDPR Article 6 lawful basis compliance) — controls TelemetryDeck. When OFF, no signals sent. Store in @AppStorage("analyticsEnabled"). Check before every TelemetryDeck.signal() call. **Prompt during onboarding page 1:** inline toggle "Help improve DailyArc with anonymous analytics" (unchecked by default, with brief explanation: "No personal data, ever").
   - **Analytics blind spot acknowledgment:** With opt-in analytics, expect 15-20% opt-in rate. Post-launch monitoring thresholds will have low sample sizes. Mitigation: (a) MetricKit provides crash-free rate, app launch time, and hang diagnostics WITHOUT consent (Apple's built-in system, no PII, legitimate interest per Art. 6(1)(f)), (b) App Store Connect provides download counts, retention estimates, and crash reports natively, (c) interpret TelemetryDeck metrics with confidence intervals appropriate for the opt-in sample size. MetricKit is the fallback for core performance metrics when TelemetryDeck sample is insufficient.
   - "Privacy Policy" link → SafariView with REAL URL
   - Data consent: "Your data stays on this device."

   Premium & Billing:
   - Show premium status or upgrade button
   - "Restore Purchases"
   - StoreKit states: idle/loading/success/error

   About: version, feedback mailto, rate button (SwiftUI .requestReview() after 7-day streak, NOT deprecated SKStoreReviewController)

2. NotificationService:
   - requestPermission(): UNUserNotificationCenter.requestAuthorization
   - scheduleEveningReminder(time:): if no habit logged today
     * Title: "You've got this"
     * Body variants (15 variants — rotate by `stableHash(dateString) % count` to prevent weekly repetition):
       - "A quick check-in keeps the momentum going. Tap to log your day."
       - "Your arc keeps building with each day you show up."
       - "Today's check-in shapes tomorrow's trend. One tap."
       - "Even a quick log adds to your arc."
       - "Your habits are waiting — they take less than a minute."
       - "End the day strong. One tap per habit."
       - "Tomorrow's insights start with today's log."
       - "Small actions, big arcs. Tap to check in."
       - "Your streak is counting on you. Quick check-in?"
       - "The best time to log is right now."
       - "30 seconds to capture your day. Worth it."
       - "Your future self will thank you for logging today."
       - "Every check-in adds a data point to your story."
       - "Your arc grows one day at a time."
       - "Ready for a quick check-in? Your habits are set."
   - scheduleStreakCheckIn(): morning-after at 9 AM (configurable) if previous day had incomplete habits
     * Title: "Pick up where you left off"
     * Body: "Yesterday had some open habits — tap to backfill and keep your arc going."
     * This respects sleep, eliminates midnight time-pressure anxiety, and leverages existing date navigation
     * CRITICAL: Aggregate into ONE notification per day, not one per habit. iOS allows max 64 pending.
     * **Notification budget allocation:** Max 10 per-habit reminders + 7 days of evening/mood reminders + 3 reactivation (3/7/14 days) + 5 streak check-ins = ~25 of 64 slots. Priority order when approaching limit: (1) per-habit reminders (user-configured), (2) mood reminders, (3) streak check-ins, (4) reactivation. Weekly summary uses a single recurring slot.
     * **Worst-case validation:** Premium user with 10 habits × 7 days = 70 per-habit notification slots, exceeding the 64 iOS limit. Mitigation: cap per-habit reminders at 5 habits (the 5 with shortest streaks — most at risk). Remaining habits get aggregated into the evening reminder. Total worst case: 5×7 (per-habit) + 7 (evening) + 7 (mood) + 5 (streak) + 3 (reactivation) = 57 of 64 slots. Priority trimming kicks in above 55.
   - scheduleMoodReminder(time:): daily mood prompt
     * Title: "How are you feeling?"
     * Body variants (12 variants — rotate by `stableHash(dateString) % count`):
       - "Take 10 seconds to check in with yourself."
       - "Your mood log adds another point to your arc."
       - "A quick check-in now helps spot patterns later."
       - "How's today's arc shaping up? Tap an emoji."
       - "One emoji captures how you're feeling right now."
       - "Track your mood — your arc tells a richer story with it."
       - "How are you really? Tap to log it."
       - "Your mood data makes your habit insights smarter."
       - "Check in with yourself. It takes 5 seconds."
       - "Mood + habits = the full picture. Quick tap?"
       - "Notice how you're feeling. Your arc will remember."
       - "A moment of reflection adds depth to your day."
   - scheduleReactivationReminders(): For churned users — 3, 5, 7, 10, 14 days of inactivity (graduated re-engagement):
     * Day 3: "Your habits are ready when you are."
     * Day 5: "Your arc is still here. One tap picks up where you left off."
     * Day 7: "Every day is a good day to start again."
     * Day 10: "It's been a little while. Your habits haven't forgotten you."
     * Day 14: "No judgment — pick up where you left off anytime."
     * After Day 14: stop entirely. Respect the user's choice. No further re-engagement notifications.
   - scheduleActivationRecovery(): For new users who haven't logged:
     * 48 hours after install, no log: "Your habits are set up and waiting. One tap is all it takes."
     * Used app 3+ days then silent for 7 days: "It's been a while — your streak may have reset, but your progress hasn't."
     * Max 2 activation recovery notifications total (tracked via @AppStorage("activationRecoveryCount")). After 2, stop — respect the user's choice.
   - **Daily notification budget:** Maximum 3 notifications per day across ALL types (streak, mood, evening, recovery). Priority order: streak check-in > mood reminder > evening reminder > recovery. If budget exhausted, skip lower-priority notifications. Prevents notification fatigue.
   - **TONE GUIDE:** All notifications use warm, encouraging language. Never fear-based ("Don't break!", "Streak at risk!"), never guilt-inducing ("We miss you!"). The app celebrates showing up, not punishing absence.
   - scheduleWeeklySummary(): fires Sunday evening (user-configurable time, default 6 PM):
     * Title: "Your week in review"
     * Body variants (8 variants — rotate by week number % count, including low-activity variants):
       - "You logged {N} habits across {D} days this week. Your top streak: {emoji} {streak}. Tap to see your arc."
       - "This week's arc: {N} habits, {D} active days. See how your week shaped your mood."
       - "Another week on your arc. {D} days logged, {streak}-day streak going strong."
       - "{D} days this week — every one counts. See your arc."
       - "Your best day was {bestDay} — {X} habits completed. See the full week."
       - "This week's highlight: {topHabitEmoji} {topHabitName} stayed consistent."
       - (low-activity, D <= 2): "Even light weeks add to your arc. See where you are."
       - (zero-activity, D == 0): "Your arc is waiting whenever you're ready. No pressure."
     * Deep link: `dailyarc://stats` → Stats tab. On arrival via this deep link, show a brief "This Week" overlay card (dismissible, 3s auto-dismiss) with mini bar chart of 7 days + top streak + mood average before showing full Stats view.
     * Share CTA: "Share your week" button in the overlay card → weekly recap share card.
     * Slot budget: uses 1 recurring slot (accounted in notification budget).
   - cancelAll(): clear scheduled notifications
   - On toggle change: schedule or cancel relevant notifications
   - **Phase 1 localization (v1.0 — App Store listing + notifications):** All notification titles and at least 4 body variants per type MUST be wrapped in `String(localized:)` and translated for Phase 1 markets (DE, JP, PT-BR). Minimum localized set:
     * Evening: 4 of 15 variants (prioritize the most arc-themed)
     * Mood: 4 of 12 variants
     * Weekly summary: 3 of 8 variants (including both low-activity variants)
     * Reactivation: all 5 (these are conversion-critical)
     * Use professional translation (same vendor as App Store copy, ~$100 additional).
   - **Easter egg copy localization:** The three v1.0 Easter eggs (100th open, seasonal tints, palindrome streak) should use `String(localized:)` wrappers. Provide English strings only for v1.0; professional translations in v1.1 Phase 2. Easter eggs in untranslated English are acceptable for non-blocking delight moments.
   - **Journaling prompt localization:** All 20+ prompts wrapped in `String(localized:)`. Translate 10 most-used prompts for Phase 1 markets in v1.0; remaining in v1.1.

3. ExportService:
   - CRITICAL: Uses DTO structs (HabitDTO: Codable, Sendable; HabitLogDTO: Codable, Sendable; MoodEntryDTO: Codable, Sendable) to break circular @Relationship for Codable encoding. Explicit `Sendable` conformance required because DTOs cross actor boundaries via Task.detached. Habit <-> HabitLog @Relationship causes infinite loops in JSONEncoder.
   - **`@Sendable` closure requirement (Swift 6):** All `Task.detached` closures in ExportService MUST be annotated `@Sendable`. Example: `Task.detached { @Sendable in ... }`. Without this annotation, Swift 6 strict concurrency will emit a warning (or error under `-strict-concurrency=complete`) because the closure captures values that cross isolation boundaries. This applies to ALL `Task.detached` blocks throughout the codebase: ExportService export, CorrelationEngine computation, RuleEngine computation. Audit every `Task.detached` call site and add `@Sendable` annotation.
   - exportToJSON(habits:, logs:, moods:) -> Data: Convert to DTOs, encode. **FREE for all users (GDPR Article 20).** Runs on Task.detached with progress indicator. Progress reporting: use `AsyncStream<Double>` to bridge progress updates from `Task.detached` back to @MainActor UI. Report every 100 objects. If user dismisses the export sheet, cancel the detached task via stored `Task` handle. Maximum export time budget: <5 seconds for 1 year of data (~2,500 objects). **HealthKit export filtering:** Exclude `HabitLog` entries where `isAutoLogged == true` from the export payload. HealthKit-sourced data belongs to Apple's Health ecosystem and must not be re-exported outside it (Apple HealthKit guidelines + privacy policy promise). Users who want their HealthKit data can export directly from the Health app.
   - exportToCSV(habits:, logs:, moods:) -> Data: flat format (PREMIUM)
   - importFromJSON(data:) -> (habits:, logs:, moods:): decode DTOs, convert to models (PREMIUM)
   - Merge mode: skip existing IDs. Overwrite mode: delete all, import.
   - **Scratch ModelContext management:** The import scratch context is created from the same `ModelContainer` as the main context but with `autosaveEnabled = false`. After successful import and `scratchContext.save()`, the main context must be refreshed to see the imported data. Call `mainContext.processPendingChanges()` or trigger a re-fetch via `@Query` invalidation (toggle a `@State` flag that triggers `.onChange`). Without this refresh, the main context's in-memory cache may show stale data until the next app relaunch.
   - **Post-import reconciliation (mandatory):** After import completes: (1) call `StreakEngine.recalculateStreaks()` for ALL imported habits (cached streak values will be stale), (2) refresh widget JSON via `DebouncedSave` flush, (3) invalidate any cached CorrelationEngine results, (4) show completion toast: "{N} habits, {M} logs imported." **If import fails mid-way, discard the scratch context** — SwiftData has no `rollback()` API. Instead, create a separate `ModelContext` for import operations (do NOT use the app's main context). If import succeeds, call `scratchContext.save()`. If it fails, simply discard the scratch context (let it deallocate) — unsaved changes are automatically discarded. Ensure `autosaveEnabled = false` on the scratch context to prevent auto-commit of partial data. Do NOT call `save()` until import is fully validated.
   - ExportServiceTests: round-trip test (export → import → compare)
   - **CRITICAL:** `@Model -> DTO` conversion MUST happen on `@MainActor` BEFORE dispatching to `Task.detached` (same pattern as CorrelationEngine snapshot extraction). Never pass `@Model` objects to a detached task.

4. Age Verification Gate (H7 — date-of-birth, not binary):
   - **Embedded inline in onboarding Page 1** (not a separate pre-onboarding screen — reduces friction, see Screen 1 spec)
   - Date-of-birth picker (month + year — sufficient for COPPA age check)
   - Calculate age from month+year. If under 13: block app with COPPA explanation
   - Store in Keychain via `KeychainService.setDOB(month:year:)` — NOT @AppStorage (survives reinstall, prevents COPPA bypass). Month+year is the minimum needed for accurate COPPA age verification. On first launch, check Keychain for existing DOB before showing age gate (reinstall protection).
   - "Why do we ask?" link explaining COPPA requirement
   - **EU Digital Consent (GDPR Article 8) — locale-aware age gate for Phase 1 markets:** The DOB age gate MUST check the user's `Locale.current.region` and apply the correct digital age of consent: Germany (DE) = 16, Brazil (BR) = 18 (LGPD Art. 14 — parental consent for under-18), Japan (JP) = N/A (no equivalent), US = 13 (COPPA). Implementation: after calculating age from DOB, compare against a dictionary `[String: Int]` mapping region codes to minimum ages (default 13). If the user's age is below their region's threshold but >= 13, show a parental consent screen: "In your region, users under {threshold} need parental approval. Please ask a parent or guardian to confirm." with a "Parent/Guardian Confirms" button. This is a soft-gate (not a hard block like COPPA), consistent with Art. 8(2) which allows member states to set thresholds. Store parental consent date in Keychain via `KeychainService.setParentalConsentDate(_:)` (consistent with DOB storage — survives reinstall). Privacy policy note: "In jurisdictions where the digital age of consent exceeds 13, parental approval is required before using this app, as described during onboarding."

5. GDPR Consent Flow (H6):
   - After age gate, before onboarding
   - Required toggle: "I consent to on-device data processing"
   - Optional toggle: "I consent to HealthKit data usage"
   - "View Privacy Policy" link
   - Store @AppStorage("gdprConsentDate") and @AppStorage("gdprConsentVersion") — version is a hash of the consent text shown (SHA256 of concatenated toggle labels + privacy policy version string). When privacy policy changes, compare stored hash to current; if different, re-prompt consent on next launch. This satisfies GDPR Art. 7(2) requirement that consent be informed — stale consent from an outdated policy is not valid consent.

5. Consent withdrawal UI (GDPR Art. 7(3) — "Withdraw Processing Consent" toggle in Health & Privacy):
   - Toggle in Settings → Health & Privacy section. When toggled OFF:
     * Show confirmation: "Withdrawing consent will stop all data processing. Correlations, analytics, and HealthKit sync will be disabled. Your data stays on your device."
     * If confirmed: set `@AppStorage("gdprConsentWithdrawn") = true`, clear `gdprConsentDate`. Disable CorrelationEngine, stop TelemetryDeck, pause HealthKit observers. DebouncedSave skips `performSave()`. Show read-only mode banner in Today View: "Data processing paused. Re-enable in Settings → Privacy."
     * Withdrawal must be same number of taps as granting consent (Art. 7(3) "as easy as" requirement).
   - **Distinct from "Delete All My Data" (Art. 17)** — withdrawal stops processing but retains data on-device. Deletion is a separate button below the toggle.
   - Re-enable: toggle ON → re-consent flow (same 3 toggles from onboarding). Clear `gdprConsentWithdrawn` flag, set new `gdprConsentDate`.

6. Accessibility: all form controls labeled, toggle states announced.

Test: Notifications schedule correctly, export produces valid JSON/CSV, import works both modes, age gate blocks under-13, privacy policy link works, consent withdrawal disables processing, consent re-grant re-enables features.
```

### Step 7a: Onboarding, Tab Navigation, Share Cards

> **See also:** Screen 1 Onboarding spec (line ~1130), Navigation Architecture (line ~1080), Share card visual spec, NavigationPath route enums (line ~1175), Milestone checklist "After Step 7a"

```
Build onboarding, navigation, and viral mechanics for DailyArc:

1. ContentView — Tab navigation (3 tabs, NOT 4):
   - Tab 1: "Today" (house.fill) → TodayView
   - Tab 2: "Stats" (chart.line.uptrend.xyaxis) → StatsView (includes Insights segment)
   - Tab 3: "Settings" (gear) → SettingsView
   - **Tab appearance:** Selected = accent color (`.monochrome`), unselected = `textTertiary` (`.monochrome`).
   - **Tab badges:** Today tab shows dot indicator if unlogged habits remain for today. Stats tab shows dot when new insights are available (post-14-day unlock, unseen). Clear badge on tab selection.
   - @AppStorage("selectedTab") for persistence
   - Gate: if !hasCompletedOnboarding → OnboardingView (age + consent are embedded in onboarding page 1, not separate screens).

2. OnboardingView (3 pages, .tabViewStyle(.page)):
   - Page 1: Welcome — icon (scale-up entrance animation with arc-drawing motion: the 270° arc animates from 0° to 270° over 0.8s, drawing the logo on screen), title, tagline "Every day adds to your arc." (reinforces the arc metaphor — your daily actions build a larger trajectory of growth), 3 value props with staggered fade-in (0.1s delay each), "Get Started" button with .spring entrance. The arc concept is the emotional throughline: each day is a point on your personal growth arc.
   - Page 2: Habit Templates — "Choose 1-3 habits" (minimum 1, maximum 3 — matches free tier limit, prevents immediate paywall friction). "Skip" link for niche habits. Haptic .selection on each template tap. Selected templates animate with checkmark + scale pulse.
   - Page 3: First Check-In Preview — mock Today View, interactive mood preview (does NOT save). "Start Tracking". When user taps mood emoji, play completion pop sound + confetti preview (teaches the reward loop before real use).
   - On complete: create selected Habits in SwiftData, set @AppStorage("hasCompletedOnboarding") = true. Brief "You're all set!" celebration with haptic .success before transitioning to Today View.

3. Share Cards (H13 — v1.0 viral loop):
   - At milestones 7/30/60/100/365/500/1000, show "Share your streak!" button. ImageRenderer runs ONLY on user tap of Share button (lazy rendering — NOT eager at celebration time). This avoids main-thread contention during the confetti + haptic + toast celebration moment. ImageRenderer MUST run on @MainActor (requires SwiftUI view access). Do NOT use Task.detached for rendering.
   - "I just hit a {N}-day streak with DailyArc!" + app branding + secondary tagline "Every day adds to your arc." as footer caption (per tagline hierarchy)
   - Include App Store short link at bottom of card (e.g., "apps.apple.com/app/dailyarc/id{APPID}") for attribution
   - Include small QR code in bottom-right corner pointing to App Store listing (generated via CoreImage CIQRCodeGenerator) — enables one-tap install from screenshot
   - **Recipient CTA:** Below the QR code, include small text: "Track your own habits → DailyArc" in white at 50% opacity. This tells share card recipients what to DO — without it, the card is a brag that doesn't convert.
   - Share via standard ShareLink
   - Privacy: if habit name sounds health-related ("Medication", "Therapy"), use generic "a daily habit"
   - **Free user sharing:** Free users CAN share basic streak cards (streak count + completion %). Full insight dashboard is premium-gated. However, free users get ONE insight share card after Day 14 (see below) as a viral conversion mechanic.
   - **Insight share card (Day 14+ premium users):** At 14+ days of paired data, offer a second share card variant: "DailyArc showed me: on exercise days, my mood averages 4.2. What would yours reveal?" This creates a curiosity gap that drives installs more effectively than streak numbers alone. Only available to premium users (insight data is premium-gated). Track variant share rates separately in TelemetryDeck.
   - **Free user insight share:** After 14 days of paired data, free users get ONE insight share card showing their single strongest correlation. The share card includes "Want to see all your insights? Get DailyArc Premium." CTA. This turns engaged free users into viral ambassadors while preserving premium gate on the full insights dashboard.
   - This is the ONLY viral loop at launch — do not defer
   - Track share card generation count in TelemetryDeck analytics
   - **Earlier/more frequent share triggers (v1.0):** In addition to milestone-triggered share cards, offer a persistent "Share" button in PerHabitDetailView (Stats → habit drill-down) that generates a stats share card: "{emoji} {name}: {currentStreak}-day streak, {completionRate}% this month." This gives users an always-available share surface beyond milestone moments. Also add a "Share your week" option to the weekly summary notification deep link (Stats tab → pre-generated weekly recap card).
   - **Weekly recap share card spec:** Dimensions: 1080x1350px (@2x, same as milestone cards). Layout: "My Week" header (titleLarge, white), 7-day completion bar chart (Mon-Sun, habit-colored bars), total completions count, top streak highlight, mood trend line (5 emoji scale), "DailyArc" wordmark + QR code at bottom. Background: same gradient as milestone cards. Generated lazily via `ImageRenderer` when user taps "Share your week." Privacy guard: same keyword check as milestone cards. Campaign tag: `ct=share_weekly`.

4. BadgesView (Badge Collection):
   - Accessible from Stats tab → "Badges" navigation link in header
   - Grid of earned badges (2 columns, LazyVGrid): emoji enlarged (60pt), badge name, date earned
   - Locked badges: emoji rendered with `.grayscale(1.0)` modifier at 60% opacity, background `backgroundTertiary`, no border. Label below: "???" in `caption` `textTertiary`. Progress bar: thin accent bar (3pt height) showing % toward unlock if calculable (e.g., "85 of 100 days"). Text: "X days to go" in `caption2`.
   - Earned badges: full color emoji at 60pt, date earned in `caption2` below, subtle gold ring border (1pt, `premiumGold`).
   - "Latest badge" spotlight at top: most recent badge enlarged (80pt) with subtle idle shimmer (respecting reduce motion)
   - Total progress: "You've earned X of Y badges" with progress bar
   - **Empty state (0 badges earned):** Illustration from Illustration Style Guide (empty badges variant — single badge silhouette with sparkle) + "Your first badge is closer than you think. Log a habit for 3 days to earn it." + accent-colored "Start Logging" button that navigates to Today tab. The empty state should inspire, not deflate.
   - Tapping earned badge shows unlock ceremony replay (without sound)
   - Badge unlock ceremony (on first earn) — **tiered by badge rarity:**
     * **Starter badges (3-14 day streaks, volume badges):** Inline toast (1.5s) + haptic `.success`. No modal.
     * **Milestone badges (30-60 day streaks):** Modal card with spring animation (.response: 0.5, .dampingFraction: 0.5), badge emoji scaled 80pt→120pt→80pt, "New Badge Unlocked!" title, badge name + description, chime sound, haptic `.success`, "Share" + "Nice!" buttons.
     * **Summit badges (100-365 day streaks):** Full-screen modal with confetti (75 particles), golden border glow, badge emoji 120pt with shimmer, fanfare sound, haptic `.success` + `.heavy`, "Share" + "Amazing!" buttons.
     * **Zenith badges (500-1000 day streaks):** Full-screen with custom particle effect (stars, not confetti), platinum border, 3-second entrance animation, unique sound, haptic sequence, "Share Your Arc" + "Incredible!" buttons.
     Reduce motion: no scale/particle animation, instant appear for all tiers.
  - **Tier sensory differentiation (users should feel the progression):**
    * Starter: single haptic tap, brief pop sound, 1.5s total duration. Feels like "nice."
    * Milestone: sustained haptic + chime, badge-colored glow, 3s total duration. Feels like "achievement."
    * Summit: haptic sequence (tap-pause-strong), fanfare, golden sparkle ring, 5s total duration. Feels like "summit reached."
    * Zenith: extended haptic sequence, unique sound, full-screen particles, 8s total duration. Feels like "transcendent."
    Each tier should be unmistakably different from the previous — a user who experienced a Milestone should feel the leap when they hit Summit.

**Share card visual design:**
- Dimensions: 1080x1350px (@2x) for Instagram/social feeds (4:5 aspect ratio — degrades gracefully in all contexts)
- Background: gradient from Sky (#2563EB) to Indigo (#5F27CD) at 135 degrees (matches app icon)
- Layout: large streak number centered (displayLarge, white), habit emoji above (80pt), milestone badge below, secondary tagline "Every day adds to your arc." in `caption` (white, 60% opacity) below badge, "DailyArc" wordmark at bottom-left, QR code at bottom-right (encoding campaign-tagged URL with `ct` parameter)
- Typography: SF Pro Display Bold, white text with subtle drop shadow for readability on gradient
- Privacy guard: uses the canonical health keyword list (see Streak Milestone Celebrations → Share cards → Privacy guard section) — do NOT maintain a separate list here. Reference the same `PrivacyKeywordFilter` that checks against 30+ English keywords + per-locale translations + per-habit "Keep private" toggle.
- Max render size: clamped to @2x at 1080x1350pt via ImageRenderer to prevent oversized images at large Dynamic Type

4. Haptic feedback throughout (**must match authoritative Haptic Feedback Map table — do NOT deviate**):
   - .light impact on habit tap (incomplete → progressing); .success notification when reaching targetCount
   - .selection on mood emoji, activity tag toggle
   - .success notification on all-habits-complete, milestone
   - .light impact on streak loss (compassionate, NOT .warning — see Streak Loss Compassion section)

5. Strategic review solicitation: after 7-day streak, use SwiftUI .requestReview() environment action (NOT deprecated SKStoreReviewController). Track in @AppStorage("hasRequestedReview").

6. Accessibility audit:
   - All views support Dynamic Type
   - Habit rows: accessibilityLabel + accessibilityValue
   - Mood emojis: "Mood: great, 5 out of 5"
   - Heat map: accessibilityLabel per cell (use fixed detail bar below map, NOT tooltip popover which conflicts with scroll)
   - Charts: accessibilityChartDescriptor
   - Confetti: if reduce motion enabled, show "All done! ✅" instead of animation. Announce via accessibilityAnnouncement.

Test: Onboarding creates habits (1-4 templates or skip), share cards render with privacy guard, haptics fire, review solicitation triggers once, VoiceOver reads all elements.
```

### Step 7b: Widgets

> **See also:** WidgetDataService spec, Widget extension memory budget (<25MB target), App Group configuration, Milestone checklist "After Step 7b"

```
Build WidgetKit support for DailyArc:

1. WidgetDataService (Services/WidgetDataService.swift):
   - Writes JSON to UserDefaults(suiteName: "group.com.dailyarc.shared")
   - **Type-safe Codable struct** (shared between app target and widget extension). **Sharing mechanism:** Create a `DailyArcShared` Swift package (local package, not a framework — simpler for solo development) containing `WidgetPayload.swift`. Add the package as a dependency to both the main app target and the widget extension target in Xcode. This guarantees compile-time type safety — any schema change in `WidgetPayload` is checked by both targets simultaneously. Alternative: simply add the file to both targets (simpler but error-prone if the file diverges). The local package approach is preferred.
     ```swift
     struct WidgetPayload: Codable, Sendable {
         let schemaVersion: Int  // Currently 2
         let completionPercent: Double
         let topStreak: Int
         let topStreakEmoji: String
         let moodEmoji: String
         let habitsDone: Int
         let habitsTotal: Int
         let isPremium: Bool
         let weeklyCompletions: [Double]  // 7 elements, most recent last

         /// Decode-fallback strategy for version compatibility.
         /// Uses decodeIfPresent with defaults so a v1 widget extension can gracefully handle a v2+ payload.
         init(from decoder: Decoder) throws {
             let container = try decoder.container(keyedBy: CodingKeys.self)
             schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
             completionPercent = try container.decodeIfPresent(Double.self, forKey: .completionPercent) ?? 0
             topStreak = try container.decodeIfPresent(Int.self, forKey: .topStreak) ?? 0
             topStreakEmoji = try container.decodeIfPresent(String.self, forKey: .topStreakEmoji) ?? "🔥"
             moodEmoji = try container.decodeIfPresent(String.self, forKey: .moodEmoji) ?? ""
             habitsDone = try container.decodeIfPresent(Int.self, forKey: .habitsDone) ?? 0
             habitsTotal = try container.decodeIfPresent(Int.self, forKey: .habitsTotal) ?? 0
             isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
             weeklyCompletions = try container.decodeIfPresent([Double].self, forKey: .weeklyCompletions) ?? Array(repeating: 0, count: 7)
         }
     }
     ```
   - Example JSON: `{ "schemaVersion": 2, "completionPercent": 0.75, "topStreak": 12, "topStreakEmoji": "🏃", "moodEmoji": "🙂", "habitsDone": 3, "habitsTotal": 4, "isPremium": false, "weeklyCompletions": [0.8, 1.0, 0.6, 0.75, 1.0, 0.5, 0.0] }`
   - Encode via `JSONEncoder` / decode via `JSONDecoder` — compile-time type safety prevents silent schema drift between app and widget
   - **NOT independently debounced** — WidgetDataService does NOT have its own 300ms timer.
   - Called from DebouncedSave's `performSave()` success path — after `context.save()` succeeds, call `WidgetDataService.writeNow()` synchronously. DebouncedSave's 300ms coalescing already prevents rapid writes, so WidgetDataService is a simple synchronous JSON encoder + UserDefaults write. Only one debounce layer (DebouncedSave), not two.
   - **Full function definition:**
     ```swift
     enum WidgetDataService {
         /// Accepts ModelContext so it can query exactly the data it needs.
         /// Called from DebouncedSave.performSave() after context.save() succeeds.
         /// PERFORMANCE: This method runs synchronously on every successful save (via DebouncedSave).
         /// It executes 3 fetches — all are indexed and bounded:
         /// - Habits: filtered by isArchived (small result set, typically <20)
         /// - HabitLogs: filtered by date >= weekAgo (7 days × ~20 habits = ~140 logs max)
         /// - MoodEntry: sorted by date, fetchLimit=1
         /// Total budget: <50ms on iPhone XS. If exceeding budget, cache habits between saves
         /// (invalidate on habit create/edit/archive only, not on every log save).
         static func writeNow(context: ModelContext, calendar: Calendar) throws {
             let habits = try context.fetch(FetchDescriptor<Habit>(predicate: #Predicate { $0.isArchived == false }))
             let today = calendar.startOfDay(for: Date())
             let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
             let logs = try context.fetch(FetchDescriptor<HabitLog>(predicate: #Predicate { $0.date >= weekAgo }))
             // Filter mood to today — prevents stale mood from weeks ago appearing on widget
             var moodDescriptor = FetchDescriptor<MoodEntry>(predicate: #Predicate { $0.date >= today }, sortBy: [SortDescriptor(\.date, order: .reverse)])
             moodDescriptor.fetchLimit = 1
             let latestMood = try context.fetch(moodDescriptor).first
             let isPremium = UserDefaults.standard.bool(forKey: "isPremium")
             // Filter todayLogs by active habit IDs — archived habits' logs should not appear in widget
             let activeHabitIDs = Set(habits.map(\.id))
             let todayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: today) && activeHabitIDs.contains($0.habitIDDenormalized) }
             // CORRECT: Check count >= targetCount (not count > 0) for proper completion tracking.
             // A habit with targetCount=3 and count=1 is in-progress, not "done".
             let todayHabits = habits.filter { $0.shouldAppear(on: today, calendar: calendar) }
             let habitsDone = todayHabits.filter { habit in
                 todayLogs.contains { $0.habitIDDenormalized == habit.id && $0.count >= habit.targetCount }
             }.count
             let habitsTotal = todayHabits.count
             let completionPercent = habitsTotal > 0 ? Double(habitsDone) / Double(habitsTotal) : 0
             let topStreak = habits.map(\.currentStreak).max() ?? 0
             let topHabit = habits.max(by: { $0.currentStreak < $1.currentStreak })
             let weeklyCompletions: [Double] = (0..<7).reversed().map { dayOffset in
                 let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                 let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: date) }
                 let dayHabits = habits.filter { $0.shouldAppear(on: date, calendar: calendar) }
                 let completed = dayHabits.filter { habit in
                     dayLogs.contains { $0.habitIDDenormalized == habit.id && $0.count >= habit.targetCount }
                 }.count
                 return dayHabits.isEmpty ? 0 : Double(completed) / Double(dayHabits.count)
             }
             let payload = WidgetPayload(
                 schemaVersion: 2,
                 completionPercent: completionPercent,
                 topStreak: topStreak,
                 topStreakEmoji: topHabit?.emoji ?? "🔥",
                 moodEmoji: latestMood?.moodEmoji ?? "",
                 habitsDone: habitsDone,
                 habitsTotal: habitsTotal,
                 isPremium: isPremium,
                 weeklyCompletions: weeklyCompletions
             )
             let data = try JSONEncoder().encode(payload)
             UserDefaults(suiteName: "group.com.dailyarc.shared")?.set(data, forKey: "widgetData")
             // CRITICAL: Notify widget extension to reload timelines immediately after data write.
             // Without this, widgets only update on system-determined schedule (5-15 min).
             WidgetCenter.shared.reloadAllTimelines()
         }
     }
     ```

2. SmallStreakWidget (FREE — lock screen + home screen, .systemSmall + .accessoryCircular):
   - Reads from shared UserDefaults
   - .systemSmall layout (155×155pt): 16pt content padding. topStreakEmoji (40pt) centered above "🔥 {topStreak}" (bold, 24pt, `.monospacedDigit`). "Tap to log" subtitle (gray, 12pt). Background: linear gradient Sky→Indigo at 15% opacity over `backgroundPrimary`. Corner radius: system default (widget family provides this).
   - .accessoryCircular (lock screen, 76×76pt): topStreakEmoji (20pt) + streak number (bold, 16pt) centered. High contrast white-on-black. No background customization (system-managed).
   - Use AppIntentConfiguration (NOT deprecated StaticConfiguration — iOS 17+)

3. MediumTodayWidget (PREMIUM — .systemMedium, 329×155pt):
   - 16pt content padding. Two-column HStack with 12pt spacing.
   - Left column: large completionPercent "75%" (bold, 48pt, `.monospacedDigit`, accent color) with circular progress ring (stroke 6pt, accent color, track `backgroundTertiary`).
   - Right column: VStack(alignment: .leading, spacing: 8pt) — habitsDone/habitsTotal count (bodyLarge), moodEmoji (28pt), "🔥 {topStreak}" badge (bold, accent). Bottom-aligned: "Open to log" (caption, `textTertiary`).
   - Background: `backgroundPrimary`.
   - If !isPremium (from JSON flag): show a solid placeholder card (NOT `.blur()` — blur signals distrust per Insights section convention) with `backgroundSecondary` background, centered SF Symbol `lock.fill` (24pt, `textTertiary`) above "Upgrade to unlock" (bodyLarge, bold, `textPrimary`). This is consistent with the Insights segment teaser pattern (show value, not obscured content).
   - AppIntentConfiguration

4. LargeStatsWidget (PREMIUM — .systemLarge, 329×345pt):
   - 16pt content padding. VStack(spacing: 12pt).
   - Top row: HStack — mood emoji (36pt) + "🔥 {topStreak}" (bold, 20pt) + completion % (bold, 20pt, `.monospacedDigit`). Spacer between elements.
   - Middle: mini 7-day bar chart (Mon–Sun completion %, using pre-computed `weeklyCompletions` from widget JSON). Each bar: 24pt wide, max height 100pt, fill accent gradient Sky→Indigo. Day labels below in caption (6pt, `textTertiary`). Chart background: `backgroundSecondary` with 8pt corner radius.
   - Bottom: "This week: {habitsDone} habits completed" (bodyMedium, `textSecondary`).
   - Background: `backgroundPrimary`.
   - If !isPremium: show solid placeholder card (same pattern as MediumTodayWidget — solid background, NOT blur).
   - AppIntentConfiguration

5. Widget states (handle all edge cases):
   - **First launch (no data):** Show "Start your arc" with app icon (24pt) in `textTertiary`. No streak or percentage shown.
   - **Empty day (habits exist but none logged):** Show "0%" or "0/{habitsTotal}" with "Continue your arc" CTA. Normal widget layout.
   - **All complete:** Show "All done! ✨" with completion percentage "100%" in accent color. Arc-themed micro-copy rotates: "Your arc shines today", "Every habit, every day", "Full arc achieved."
   - **Error (JSON decode failure / missing data):** Show last-known-good cached data. If no cache: show "Open DailyArc" fallback. Never show a blank or crashed widget.
   - **Redacted placeholder (system):** Use `.redacted(reason: .placeholder)` on content views — SwiftUI handles shimmer automatically.
   - All widget families handle these states consistently.

   **Dark mode widget rendering:** All widget backgrounds use `backgroundPrimary` (adapts automatically via `Color(light:dark:)` tokens). Streak fire emoji and text use `textPrimary` (white in dark mode). The Sky→Indigo gradient on SmallStreakWidget uses 15% opacity in both modes — the gradient is subtle enough that it works on both light and dark backgrounds. **Test:** Verify all 4 widget sizes in both light and dark mode in Xcode previews AND on a real device (simulator colors can differ).

   **Widget personality & seasonal variants:**
   - **Arc-themed placeholder copy** (used in "Start your arc" and empty states): rotate between "Your arc awaits", "Today's arc starts here", "One tap begins your arc."
   - **Seasonal widget accents (v1.0):** Widgets subtly reflect the season via the greeting text (already specified in greetings section) AND a seasonal accent color overlay at 5% opacity on the background gradient:
     * Spring (Mar-May): fresh green tint
     * Summer (Jun-Aug): warm amber tint
     * Autumn (Sep-Nov): soft orange tint
     * Winter (Dec-Feb): cool blue tint
   - Seasonal detection: `Calendar.current.component(.month, from: .now)` — no server dependency.
   - **Widget streak milestone callouts:** When `topStreak` hits milestones (7, 30, 100, 365), the streak display adds a brief qualifier: "🔥 7 — One week!", "🔥 30 — Blazing!", "🔥 100 — Legendary!", "🔥 365 — Full arc!"

6. Widget deep links:
   - SmallStreakWidget: `.widgetURL(URL(string: "dailyarc://today")!)` — opens Today tab
   - MediumTodayWidget: `.widgetURL(URL(string: "dailyarc://today")!)` — opens Today tab
   - LargeStatsWidget: `.widgetURL(URL(string: "dailyarc://stats")!)` — opens Stats tab
   - In DailyArcApp.swift: `.onOpenURL { url in selectedTab = url.host == "stats" ? .stats : .today }`
   - Register URL scheme "dailyarc" in Info.plist (CFBundleURLSchemes)

6. Widget timeline: .atEnd reloading policy. Also reload via WidgetCenter.shared.reloadAllTimelines() when app enters foreground. **Throttle refreshes:** Track last reload timestamp in `@AppStorage("lastWidgetReload")`. Skip `reloadAllTimelines()` if called within 60 seconds of the last reload. Apple's WidgetKit has its own throttling, but client-side throttling prevents unnecessary IPC calls during rapid tap-save cycles.
   **Widget timeline budget:** Apple limits widget refreshes to ~40-70 per day (varies by user engagement). The timeline provider MUST use `.atEnd` (not `.after(date:)` with short intervals). Budget allocation: ~24 hourly refreshes (for date change, midnight rollover) + ~20 user-triggered refreshes (habit taps via `reloadAllTimelines()`) + ~10 buffer = ~54 total, within typical budget. The `getTimeline` implementation should return a single entry (current state) with `.atEnd` policy — never return multiple future entries (wastes budget and shows stale predictions). Profile widget refresh frequency in TestFlight via TelemetryDeck signal `widget_timeline_requested`.

7. App Group: configure "group.com.dailyarc.shared" in both main app target and widget extension target.

Test: Widgets display pre-computed data, premium gates work, data updates within 1 second of habit log, widget renders correctly in all sizes.
```

### Step 8: HealthKit Integration, Polish, Pre-Submission

> **See also:** HealthKit spec (line ~2430), HabitLogWriteActor (line ~429, replaces HealthKitModelActor), BackgroundTaskService protocol, DedupService (30-day scope), Pre-Launch Checklist Phase 3-4, App Store Nutrition Labels, Milestone checklist "After Step 8"

```
Final integration and polish for DailyArc:

1. HealthKitService full implementation (uses @ModelActor for thread safety — see B5):
   - requestAuthorization(for types: Set<HKObjectType>) async throws
   - Per-type query strategy (see H1):
     * Steps → HKStatisticsCollectionQuery (daily sum aggregates, quantity type)
     * Workouts → HKSampleQuery (filter by HKWorkoutType, count per day)
     * Sleep → HKSampleQuery on HKCategoryType(.sleepAnalysis), filter .inBed/.asleepUnspecified, sum hours
     * Mindful Minutes → HKSampleQuery on HKCategoryType(.mindfulSession), sum durations (NOT a quantity type)
   - backfillHabitLogs(habitID: UUID, typeRaw: String, days: 30): dispatch to correct query type based on typeRaw. Takes Sendable parameters, NOT @Model Habit.
   - registerObserver(habitID: UUID, typeRaw: String, writeActor: HabitLogWriteActor): HKObserverQuery for ongoing sync. Captures UUID, not @Model.
   - When observer fires: use HabitLogWriteActor.saveLog(habitID:date:count:isAutoLogged:true:calendar:) for thread-safe SwiftData writes
   - CRITICAL: Never send isAutoLogged==true data off-device (enforced by no-API architecture)
   - Info.plist required key: NSHealthShareUsageDescription = "DailyArc reads your workouts, steps, sleep, and mindful minutes to auto-log habits you've linked to Health data."
   - Test with Health simulator data

2. Performance optimization:
   - Verify heat map Canvas renders in <100ms (profile with Instruments)
   - Verify streak cache prevents O(n) recalculation on view load
   - Verify DaySnapshot batch computation (not individual queries)
   - Verify widget reads from UserDefaults (not SwiftData)
   - Profile memory on 365-day heat map
   - Verify debounced auto-save (300ms) prevents write storms
   - **Per-screen memory budgets (verify with Instruments Allocations):**
     * TodayView: <30MB (active habits + today's logs)
     * StatsView (30-day): <50MB (chart data + per-habit cards)
     * StatsView (365-day heat map): <80MB peak during computation, <50MB steady state
     * OnboardingView: <20MB (minimal — static content + template data)
     * HabitFormView: <15MB (form fields + emoji picker grid)
     * PaywallView: <10MB (static content + StoreKit product data)
     * SettingsView: <15MB (form fields + UserDefaults reads)
     * Widget extension: <30MB (WidgetKit hard limit is 30MB — stay under 25MB)
     * Total app: <150MB at all times (DebugDataGenerator 365-day dataset)
   - **Cold launch target: <1.0 second to interactive TodayView.** Budget breakdown by phase:
     * App init + ModelContainer creation: <200ms
     * @Query resolution (today's habits): <100ms
     * TodayView first frame render: <200ms
     * Deferred (after first frame, via `task { }`): TelemetryDeck init (<50ms), StoreKit entitlement check (<100ms), HealthKit observer re-registration (<100ms), Keychain reads (<50ms), DedupService check (<200ms), widget data refresh (<100ms)
     * Total critical path: <500ms. Deferred tasks run concurrently where possible (tasks 1-3 overlap) — wall-clock for concurrent group: ~100ms. Serial chain (4→5→6): ~500ms. Total deferred wall-clock: ~600ms. **Total to interactive: <500ms (critical path). Total including all deferred: <1.1s.** The stated <1.0s target refers to the critical path to interactive TodayView; deferred tasks may extend to 1.5s but do not block the UI. (profile with Instruments App Launch template). Defer non-critical initialization to after first frame: TelemetryDeck config, StoreKit entitlement verification, HealthKit observer re-registration, widget data refresh, **Keychain reads** (stableUserID, DOB verification — move to `task { }` after first frame, not synchronous in `App.init()`). Only ModelContainer setup and @Query resolution are on the critical launch path.
     * **Launch sequence ordering and isolation:** Run deferred tasks in a structured `TaskGroup` with individual `try/catch` isolation — a DedupService failure must NOT affect StoreKit verification. Execution order: (1) TelemetryDeck init + StoreKit entitlement check (concurrent, independent), (2) HealthKit observer re-registration (independent), (3) Keychain DOB read (independent), (4) DedupService scan (should complete before widget refresh), (5) StreakEngine cold-launch reconciliation (after DedupService, before widget refresh — verifies cached streaks), (6) Widget data refresh (depends on DedupService + streak reconciliation). Total budget: <2.0s for all deferred work combined. Log `cold_launch_deferred_ms` to TelemetryDeck. **TaskGroup cancellation:** If the 1.5s group timeout fires, all remaining child tasks are cancelled even if they haven't hit their individual 500ms caps. Group timeout takes precedence over individual timeouts.
     * **Per-task timeout enforcement (CRITICAL):** Wrap each deferred task in a `withTimeout(milliseconds: 500)` helper using `Task.sleep` + cancellation. Individual task cap: 500ms. Total group cap: 1.5s (leaving 500ms headroom within 2.0s budget). **Fallback behavior per task on timeout:** DedupService → defer to next foreground cycle. HealthKit → skip re-registration, rely on existing observers. StoreKit → use cached `@AppStorage("isPremium")` value. Keychain → use cached `@AppStorage("isAgeVerified")` value. Widget refresh → skip, stale data acceptable for one session. Log `cold_launch_task_timeout` with task name to TelemetryDeck.
   - **CPU profiling targets (measure on oldest supported device — iPhone XS / A12):**
     * CorrelationEngine.computeCorrelations: <500ms for 10 habits × 365 days
     * StreakEngine.recalculateStreaks: <10ms per habit (single tap path)
     * Heat map Canvas render: <100ms for 365 cells (already specified)
     * Confetti animation: maintain 60fps throughout 2-second duration
   - **Scroll performance targets (measure via MetricKit MXScrollingDiagnostic):** All ScrollViews maintain <5ms hitch rate per scroll session. Main thread hangs <100ms (MXHangDiagnostic). All animations maintain 60fps on iPhone XS / A12 — not just confetti.

**Memory pressure handling:** Register for `UIApplication.didReceiveMemoryWarningNotification` in DailyArcApp.swift. On memory warning: (1) cancel in-flight 365-day background Task, (2) release cached correlation results and snapshot arrays, (3) fall back to 30-day dataset. Re-attempt full-year load on next foreground cycle. Priority order for memory release: 365-day snapshots first, then correlation cache, then image renderer cache.

**Offline behavior:** DailyArc is local-first — all core functionality works without network. Specific offline behaviors:
- **TelemetryDeck:** Queues signals automatically, sends when connectivity returns (built-in SDK behavior). No user-visible impact.
- **StoreKit:** `Transaction.currentEntitlements` may not reach Apple servers. Trust cached `@AppStorage("isPremium")` value. On next online session, StoreKit reconciles automatically.
- **HealthKit:** Observer queries fire regardless of network. No impact.
- **Breach notification JSON:** `dailyarc.app/security.json` fetch silently fails. App continues normally.
- **"Open Settings" links:** Always work (local URL scheme, no network needed).
- **No connectivity indicator needed** — the app should feel fully functional offline. Never show "no internet" banners for a local-first app.

**Thermal state monitoring:** Register for `ProcessInfo.processInfo.thermalState` changes via `NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification)`. Behavior by thermal state:
- `.nominal` / `.fair`: Full functionality, all animations, 60fps target.
- `.serious`: Reduce confetti particle count from 50 to 25, skip non-essential animations (greeting fade-in, skeleton shimmer), defer CorrelationEngine retries.
- `.critical`: Disable all animations (treat as reduce motion enabled), cancel background Tasks, defer DedupService to next foreground cycle. Log `thermal_critical` to TelemetryDeck with screen and action context.
This prevents the app from contributing to thermal throttling on older devices during hot weather or heavy multitasking.
**Thermal telemetry:** Log `thermal_state_change` events to TelemetryDeck with parameters: `device_model`, `current_screen`, `thermal_state` (nominal/fair/serious/critical). After launch, use this data to calibrate particle budgets and animation complexity per device class rather than fixed thresholds.

3. XCUITest smoke tests (assigned to Step 8 — write alongside polish):
   - Onboarding flow: complete 3 pages, verify habits created
   - Habit CRUD: add, edit, archive, delete with confirmation
   - Mood logging: tap emoji, verify auto-save, verify undo toast
   - Streak display: verify streak increments on completion
   - Date navigation: navigate backward, log past day, return to today
   - Paywall: verify product.displayPrice renders (StoreKit sandbox)
   - Export JSON: verify file generation for free user
   - Widget: verify data written to shared UserDefaults after habit log
   - Accessibility: verify VoiceOver labels on Today View elements

4. DedupService integration:
   - Wire `DedupService.runIfNeeded()` call in `DailyArcApp.swift` `.onChange(of: scenePhase)` when transitioning to `.active`.
   - **Algorithm:** Fetch HabitLogs from the last 30 days (`#Predicate { $0.date >= thirtyDaysAgo }`) — NOT "fetch all" (matches canonical 30-day scope at line ~426). Sort by (habitIDDenormalized, date). Walk sorted list; when consecutive entries share the same (habitIDDenormalized, normalizedDate), keep the entry with the highest `count` and delete the rest. Run in a single pass O(N log N) for sort + O(N) for walk. Use `@AppStorage("lastDedupDate")` to skip if <1 hour since last run.
   - **Budget:** <200ms on 365-day test dataset (≈2,500 HabitLog entries). **Space budget:** O(N) for the sorted array + O(D) for duplicate tracking where D << N. Peak memory: ~500KB for 2,500 entries (each UUID + Date ≈ 32 bytes × 2,500 ≈ 80KB, plus overhead). Profile with Instruments Allocations.
   - **Test:** DedupServiceTests — insert 5 duplicate pairs, run dedup, assert exactly 5 deletions and surviving entries have max count.

5. CrashReportingService integration:
   - Register `MXMetricManager.shared.add(self)` in `DailyArcApp.init()` (or first `task {}`).
   - Implement `MXMetricManagerSubscriber.didReceive(_:)` to forward `MXCrashDiagnostic` payloads to TelemetryDeck.
   - Log hang diagnostics (`MXHangDiagnostic`) for main-thread stalls >250ms.
   - No user consent required — MetricKit is Apple's system framework, legitimate interest per GDPR Art. 6(1)(f).

6. Edge cases:
   - **Timezone change behavior:** When the user's timezone changes (travel, DST), streaks MUST NOT break. All dates are normalized to `calendar.startOfDay(for:)` using the device's current calendar. This means: (1) a user who flies from NYC to LA at 11 PM EST still gets credit for that day in PST, (2) DST spring-forward does not create a "missing" day, (3) if timezone change causes two logs for the "same" calendar day, fetchOrCreate's idempotent pattern returns the existing log. Edge case: user who crosses the International Date Line may see a duplicated or skipped calendar day — accepted limitation for v1.0, document in Technical Debt
   - Midnight rollover: date navigation should update at midnight (use .scenePhase)
   - App backgrounded during habit log: auto-save already handles this
   - First-time user with 0 data: all empty states render
   - User with 365+ days of data: performance acceptable
   - Import + existing data merge: no duplicate IDs (fetchOrCreate pattern)
   - Rapid tapping: fetchOrCreate prevents duplicate HabitLogs (B3)
   - Streak off-by-one: morning shows yesterday's streak correctly (B4)

7. Dark mode audit: all habit colors resolve via colorIndex → HabitColorPalette light/dark hex. Test heat map colors, chart colors, accent swatches against WCAG AA contrast ratios in both modes.

8. Reduced motion audit: if AccessibilityEnvironment.isReduceMotionEnabled:
   - Confetti → static "All done! ✅" text with accessibilityAnnouncement
   - Streak animations → instant state change
   - Tab transitions → no custom animations

9. Privacy policy: Create actual privacy policy covering:
   - What data is collected (habits, mood, HealthKit metrics)
   - Where data is stored (on-device only, no external servers)
   - HealthKit data handling (never transmitted, never shared)
   - GDPR rights (data access, deletion, portability via free JSON export)
   - CCPA rights
   - Children's privacy (COPPA — DOB age gate enforced)
   - Mental health disclaimer: "DailyArc is a self-tracking tool, not a medical device. It does not diagnose, treat, or prevent any condition. If you're struggling, please reach out to a mental health professional."
   - Contact information
   Host at actual URL, update Settings link.

8. App Store submission prep:
   - App icon: consistent with brand (arc/circle motif, accent color)
   - Screenshots: 6.7" and 6.1" required
     1. Today view with mood + habits + confetti
     2. Heat map showing 12 months of consistency
     3. Stats with streaks + completion rings
     4. Insights: "On exercise days, your mood averages 4.2"
     5. Price comparison: "$5.99 once. No subscriptions."
   - App preview video (optional, 20-30% conversion lift)
   - Description: lead with "See how your habits shape your mood" — do NOT open with competitor names
   - Keywords: habit tracker, mood tracker, streaks, daily habits, wellness, self care, routine, journal, health, productivity
   - DO NOT include: meditation, mindfulness (misleading for this app)

9. App Store Privacy Nutrition Labels (required in App Store Connect):
   - Data Used to Track You: NONE
   - Data Linked to You: Health & Fitness (HealthKit, if user enables), Other Data (habits, mood — on-device only)
   - Data Not Linked to You: Diagnostics (if crash reporting enabled)
   - Data Not Collected: name, location, contacts, browsing, purchases, identifiers
   - **Data Linked to You (if provided):** Contact Info > Email Address (optional, marketing consent, shared with Buttondown email delivery service under DPA)
   - Note: Since all data is on-device only with no server, most categories are "Not Collected." Email is the sole exception — collected optionally during onboarding for weekly summary emails, shared with Buttondown (email delivery provider) under a signed Data Processing Agreement (GDPR Art. 28).

Test: Full end-to-end flow, VoiceOver audit, performance profiling, dark mode, reduced motion, all edge cases, HealthKit per-type queries verified.
```

---

## Milestone Checklist

| Milestone | Verification |
|-----------|-------------|
| After Step 1 | Models compile with nested VersionedSchema (typealias at module scope), StreakEngine off-by-one fixed AND includes isRecovered logs in streak count, bestStreak fully recomputes on deletion, StreakEngine does NOT call context.save() (defers to DebouncedSave), RuleEngine uses applicable days and excludes isRecovered, Color(hex:) works, fetchOrCreate uses UUID post-filter (not persistentModelID), HabitFrequency enum round-trips, #Index macro compiles (iOS 17.4+), TelemetryDeck initialized |
| After Step 2 | Today view: habits auto-save on tap (debounced 300ms), mood saves independently, date navigation uses ModelContext.fetch (not @Query) — B1 fix, streaks update on completion, confetti (Canvas, 50 particles, reduce motion fallback), streak recovery banner works, time-of-day greeting shows, undo toast appears on accidental tap, fetchOrCreate prevents rapid-tap duplicates (B3) |
| After Step 3 | Add habit with template (1 tap, minimum 1 not 2), add custom habit (2 steps), edit existing, reorder via drag, archive/unarchive, free tier enforced at 3 (with "archive frees slots" hint), notification permission requested on first toggle, pipe delimiter for customDays |
| After Step 4 | Canvas heat map renders 365 days (<100ms), mood trend chart shows with energy overlay, per-habit cards display cached streaks, drill-down stats correct, all empty states render, progressive loading (30 days → 365), heat map uses fixed detail bar (not popover) |
| After Step 5a | Premium purchase works in sandbox, paywall displays product.displayPrice (never hardcoded), free/premium gates enforced everywhere, StoreKit optimistic loading from @AppStorage cache, basic JSON export works for FREE users (GDPR Article 20) |
| After Step 5b | Pearson correlation correct (test with known data), CorrelationEngine runs via Task.detached (not Task, which inherits @MainActor), filters by shouldAppear(on:), excludes isRecovered logs, lowered thresholds produce meaningful labels (0.15/0.3/0.5), binary habits show bar chart (not scatter), energy surfaced in insights |
| After Step 6 | Notifications schedule/cancel with specified copy, streak notifications aggregated (not per-habit), export uses DTO structs (no circular @Relationship crash), export runs on Task.detached, Data Management section always visible (not behind paywall), "Delete All My Data" wipes all stores (GDPR Art. 17), age gate uses DOB picker and blocks <13, GDPR consent flow shown, reactivation reminders at 3/7/14 days, mental health disclaimer shown |
| After Step 7a | Onboarding creates template habits (min 1, skip option), 3-tab navigation persists, share cards render at milestones with QR code + App Store link + privacy guard (health-related habits → "a daily habit"), haptics fire, SwiftUI .requestReview() triggers once, VoiceOver audit passes, reduce motion: static fallback for all animations |
| After Step 7b | Widgets use AppIntentConfiguration, distinct layouts per size, deep links (dailyarc://today, dailyarc://stats), read from debounced UserDefaults JSON with schemaVersion + weeklyCompletions, premium gates in medium/large widgets, widget data updates within 1 second |
| After Step 8 | HealthKit per-type queries (statistics for steps, HKSampleQuery for workouts/sleep/mindful), @ModelActor with UUID lookup (not persistentModelID), backfillHabitLogs takes habitID+typeRaw (Sendable), NSHealthShareUsageDescription in Info.plist, MetricKit crash reporting active, performance profiled, timezone/midnight edge cases pass, dark mode via colorIndex→palette lookup, reduced motion audit complete, privacy policy hosted with mental health disclaimer, App Store Privacy Nutrition Labels configured, App Store assets ready, TestFlight go/no-go criteria met |

---

## Brand Guidelines

**Brand Purpose:** DailyArc exists to help people understand themselves better through the simple act of showing up each day. We believe self-knowledge is the foundation of well-being.

**Brand Values:**
- **Compassionate:** We celebrate effort, never punish absence. Every interaction should feel like encouragement from a friend.
- **Private:** Your data is yours alone. Privacy is our architecture, not a feature we market.
- **Honest:** We show real patterns, not gamified dopamine loops. Insights are statistical, never prescriptive.
- **Calm:** We respect attention. No notification spam, no anxiety-inducing streaks, no dark patterns.

**App Icon:** Arc/circle motif — a partial ring (270° arc) in the app's accent gradient (Sky → Indigo from color palette), set against a white/off-white background. The open gap in the arc faces upward-right, suggesting forward progress. Rounded-corner superellipse per Apple HIG. Provide @1x/@2x/@3x plus 1024×1024 for App Store.

**Color Identity:** Primary accent = Sky (#2563EB light / #54A0FF dark). Secondary accent = Coral (#E63946 light / #FF6B6B dark). These two colors anchor all marketing materials, screenshots, and the app icon.

**Voice & Tone:** Warm, encouraging, never clinical. The app is a supportive companion, not a productivity drill sergeant. Celebrations > penalties. "You did it!" > "Task complete." See TONE GUIDE in NotificationService for notification copy standards.

**Typography (marketing):** SF Pro Display for headlines, SF Pro Text for body. Match the in-app Dynamic Type scale for visual consistency between marketing materials and the actual app.

**Dark Mode as Brand Expression (authoritative — all dark mode decisions reference this section):** Dark mode is not just "inverted colors" — it is an intentional brand experience for evening and nighttime users. The emotional intent is a calm, reflective nighttime companion aligned with the evening journaling use case. The Sky accent color (#54A0FF) should feel like starlight or a guiding light rather than just a lighter-for-contrast variant. Cards use elevated backgrounds (not just darker) to create depth. The heat map's dark mode palette creates a subtle glow effect. True black OLED background is intentional — it recedes and lets content breathe, making the arc visualizations feel like they float. This brand expression informs all dark mode design decisions: when in doubt, choose the option that feels more calm and reflective.

**Iconography:**
- SF Symbol weight: `.medium` for body context, `.semibold` for headers and navigation
- Rendering mode: `.hierarchical` for most icons (adds depth), `.monochrome` for tab bar icons
- Symbol sizing: `.imageScale(.medium)` relative to adjacent text by default; `.imageScale(.large)` for empty states
- App icon construction: 270° arc, stroke width 48pt (on 1024×1024 canvas), gradient from Sky (#2563EB) to Indigo (#5F27CD) at 135° angle, 15% padding from canvas edge, gap faces upper-right at 45°

**Illustration Style Guide:**
- Style: flat vector with subtle gradients, matching the app's clean aesthetic. No 3D, no skeuomorphism, no characters/mascots.
- **Line weight:** 2pt stroke for primary elements, 1pt for secondary/detail elements. Consistent across all illustrations.
- **Dimensions:** Each illustration rendered at 200×200pt (@1x, provide @2x/@3x). Centered in container, max display height 200pt.
- Color: illustrations use brand colors (Sky, Coral, plus 2-3 palette accent colors per illustration). Background elements in `backgroundSecondary`.
- Motif: **every illustration must incorporate the arc shape** — the 270° partial ring from the app icon, used as a structural or decorative element. This is the visual thread that ties all illustrations to the brand identity.
- **Compositional rules:**
  - Arc element must occupy ≥25% of illustration area (ensures brand recognition at small sizes).
  - Maximum 3 colors per illustration (brand palette only — no arbitrary colors).
  - No text within illustrations — all labels are rendered as SwiftUI Text views below the illustration for localization and Dynamic Type support.
  - Negative space: ≥30% of canvas must be empty to maintain the clean, breathing aesthetic. Cluttered illustrations contradict the brand's "calm" value.
  - Consistency check: all illustrations must pass a "squint test" — at 50% zoom, the arc motif should still be recognizable.
- Usage: empty states (habits, stats, insights), onboarding pages, loading states, COPPA block screen.
- **Per-context illustration briefs:**
  - *Empty habits:* A partial arc (2pt stroke, dashed gray 1pt continuation line) suggesting potential — "your arc is waiting to be drawn." Sky accent color arc with dashed gray extension. The arc occupies the top 60% of the canvas; below it, a single small circle (habit dot) sits at the start of the arc.
  - *Empty stats:* The heat map grid (6×7 miniature grid) with a few cells gently glowing in Sky — a preview of what the full arc looks like. A subtle 270° arc frames the upper-left corner. Encouraging the user to keep logging.
  - *Empty insights (locked):* Two arcs converging — one in Sky (habits), one in Coral (mood) — meeting at a point where a small sparkle/starburst emerges (insight). Progress bar (1pt, `backgroundTertiary` track, Sky fill) below.
  - *Empty badges:* A single badge silhouette (circle, 64pt) with a subtle sparkle on the edge — aspiration, not a wall of locked content. Arc motif as the badge's border shape.
  - *COPPA block:* Simple shield icon in brand colors (Sky outline, 2pt stroke) — protective, not alarming. No playful elements. No arc motif (**intentional exception** to the "every illustration must incorporate the arc shape" rule — legal/brand separation for minors requires neutral presentation).
  - *Error states:* A gentle arc that has a small "bump" or kink in it — the arc continues past the bump, suggesting resilience. Below: a small "retry" circular arrow icon. Sky color for the arc, Coral for the bump. The illustration communicates "a minor interruption, not a failure." Paired with brand-voice error copy from the Whimsy & Delight → Error States section.
- Sizing: centered, max 200pt height, with 24pt (`DailyArcSpacing.xl`) vertical spacing above and below.
- Reduce motion: illustrations are static (no animated empty states in v1.0). v1.1 may add subtle idle animations.
- Do NOT use stock illustrations or illustrations that don't match the brand color palette.

**Arc Metaphor Saturation Ceiling:** The arc metaphor is powerful when used judiciously. To prevent it from becoming repetitive or self-parodying:
- **Max 3 arc references per screen** (including visual arc indicators, arc-language strings, and arc-themed copy).
- **Max 5 arc-language strings per session** (foreground→background cycle). When multiple arc-referencing elements compete, prioritize the most contextually specific one (e.g., "Your 30-day arc" > "Your arc this week" > generic "Your arc").
- Visual arc indicators (progress ring, heat map baseline) do NOT count toward the text limit — only arc-language in copy counts.
- **Exception:** Celebrations and share cards are intentionally arc-dense (the user is in a receptive emotional state) and are exempt from the per-screen limit.

**Emoji Usage Guideline:** Emojis are appropriate in: greetings, celebrations, badge names, habit identifiers, Easter eggs, toast messages, and share card copy. Emojis are NOT appropriate in: legal/privacy text, error messages (except retry CTA), COPPA block screen (intentionally neutral), or settings labels. When in doubt, prefer no emoji.

**Name usage:** Always "DailyArc" (one word, capital D, capital A). Never "Daily Arc", "dailyarc", or "DAILYARC".

**Brand Personality Traits:**
- **Warm** (not clinical) — "You showed up today" vs "Task logged"
- **Insightful** (not prescriptive) — "On exercise days, your mood averages 4.2" vs "You should exercise more"
- **Patient** (not urgent) — "Your arc is waiting when you're ready" vs "Don't break your streak!"
- **Minimal** (not sparse) — Every element earns its place, but nothing feels missing
- **Empowering** (not paternalistic) — "Here's what your data shows" vs "You need to do better"
- **Honest** (not evasive) — "Correlations are statistical, not causal" vs hiding limitations. Transparent about data, no dark patterns, clear about what the app can and cannot do.

**Anti-Terms Glossary (NEVER use in any user-facing copy):**
| Banned Term | Why | Use Instead |
|-------------|-----|-------------|
| "Don't break your streak!" | Fear-based, anxiety-inducing | "Keep building your arc" |
| "You missed a day" | Guilt language | "Pick up where you left off" |
| "Streak at risk!" | Loss aversion dark pattern | "Your arc is waiting" |
| "We miss you!" | Manipulative, anthropomorphizes app | "Your habits are ready when you are" |
| "Task complete" | Clinical, enterprise-feeling | "Done!" or "You showed up" |
| "Failure" / "Failed" | Judgmental | "Incomplete" or omit entirely |
| "Perfect score" | Implies non-perfect is bad | "Every habit today" or "Full arc" |
| "Addictive" | Negative health connotation | "Engaging" or "motivating" |
| "Crush your goals" | Aggressive, gym-bro energy | "Build toward your goals" |
| "Gamify" / "Level up" | Anti-brand; DailyArc is not a game | "Grow" / "Progress" |

**Brand Evolution Roadmap:**
- **v1.0 (Launch):** Establish core brand identity — arc metaphor, warm tone, privacy architecture. Brand is "your private companion for self-discovery."
- **v1.1 (3-6 months):** Deepen brand through "Year in Arc" annual recap, Watch app, CloudKit sync. Brand evolves to "your lifelong arc of growth." Introduce subtle premium brand differentiation (gold accents for premium features).
- **v2.0 (12+ months):** If community features are added (shared challenges, anonymized benchmarks), brand evolves to "your arc, your community." The core values (compassionate, private, honest, calm) remain constant — only the scope grows.
- **Brand guardrails that never change:** Privacy-first architecture, no guilt/fear language, no gamification terminology, one-time pricing model.

**Brand Copy Audit Checklist (pre-launch verification):**
| Copy Category | Brand Voice Register | Verify |
|--------------|---------------------|--------|
| Onboarding (Pages 1-3) | Warm, inviting | No banned terms, arc metaphor ≤3 per page |
| Greetings (20+ variants) | Supportive, brief | Streak-aware variants don't use guilt language |
| Celebrations (6 tiers) | Enthusiastic, personal | Each tier escalates appropriately |
| Streak loss (4 tiers) | Compassionate, reframing | Zero punitive language, "Missed" banned |
| Notifications (all copy) | Supportive, brief | No "Don't break" or "You missed" |
| Error states (10+ variants) | Playful, reassuring | Arc metaphor present but not forced |
| Paywall (all surfaces) | Confident, differentiating | No competitor mentions, "Unlock" not "Purchase" |
| Widget copy (all states) | Brief, arc-themed | Personality in constraints of small space |
| Legal/Settings | Clear, transparent | No emojis, no arc metaphor in legal text |
| Share card text (4 tiers) | Personal, escalating | Privacy guard for health-related habits |

**Brand Positioning Statement:** DailyArc is the only habit tracker that connects what you do to how you feel, entirely on your device, for one price. Unlike subscription trackers that lock data behind monthly fees, DailyArc gives permanent ownership of habits, insights, and privacy. Brand promise hierarchy: (1) Primary = insight discovery ("see how your habits shape your mood"), (2) Secondary = privacy architecture ("your habit and mood data stays on your device"), (3) Tertiary = value pricing ("one payment, yours forever").

**Brand Voice Matrix:**
| Context | Register | Example |
|---------|----------|---------|
| Onboarding | Warm, inviting | "Every day adds to your arc." |
| Daily use | Supportive, brief | "You've got this." |
| Celebrations | Enthusiastic, personal | "30 days. You've proven something to yourself." |
| Streak loss | Compassionate, reframing | "That's X more than zero." |
| Errors/loading | Playful, reassuring | "Crunching your numbers..." |
| Marketing/ASO | Confident, differentiating | "Privacy is not a feature. It is the architecture." |
| Legal/settings | Clear, transparent | "Your habit and mood data stays on this device." |
| Social / Twitter | Authentic, educational, conversational | "Here's what I learned building DailyArc this week." |
| Reddit | Value-first, community-aware, never promotional | "I've been tracking X for 90 days. Here's my data." |
| Email drip | Warm → confident (escalating) | "Your arc is growing. Here's what your data shows." |

### Target User Personas

**Competitive UX Audit (informing design decisions):**
DailyArc's UX is informed by analysis of the top 5 habit/mood trackers (Daylio, Streaks, Habitify, Habitica, Done):
- **Daylio:** Strong mood logging UX, but habit-mood correlation is manual/absent. DailyArc differentiates with automated Pearson correlation. Daylio's subscription model ($36/yr) creates conversion friction — DailyArc's one-time $5.99 removes ongoing cost anxiety.
- **Streaks:** Excellent minimalism (6-habit grid), but no mood tracking and rigid UI. DailyArc adds mood without compromising simplicity. Streaks' lack of insights means users don't know IF their habits help — DailyArc answers this question.
- **Habitify:** Feature-rich but subscription-based ($5/mo) and overwhelming for new users (7+ screens onboarding). DailyArc targets the simplicity gap with one-time pricing and 3-screen onboarding.
- **Habitica:** Gamification-heavy (RPG mechanics) that alienates users seeking genuine self-improvement. DailyArc's whimsy is encouraging, not game-like — arc metaphor vs quest metaphor.
- **Done:** Clean UI but no mood integration and limited free tier (3 habits, same as DailyArc). DailyArc differentiates on insights and emotional tone.
- **Common UX failures observed:** Over-complicated onboarding (4+ screens), guilt-driven streak notifications ("You broke your streak!"), subscription fatigue, no connection between habits and outcomes, data export locked behind paywalls (GDPR risk).
- **DailyArc UX advantages:** 3-screen onboarding (vs 5+ industry average), compassionate tone (vs guilt-driven), one-time pricing (vs subscription), automated habit-mood insights (vs manual journaling), free JSON export (GDPR-compliant), privacy-first on-device architecture.
- **Competitive blind spots DailyArc exploits:** (1) No competitor combines habit tracking + mood tracking + automated correlation on-device. (2) One-time pricing is rare in the category (most are subscription). (3) Compassionate streak loss handling is unique — competitors either ignore or punish.

**Research note:** These personas are hypothesis-based archetypes derived from competitive analysis and App Store review mining of Daylio/Streaks/Habitify. Percentages are estimated. **Pre-launch validation plan (BLOCKING — complete during TestFlight beta, Weeks 14-16):** Conduct 5-8 structured 15-minute interviews with TestFlight beta participants (already recruited — zero additional cost). Interview guide: "What were you doing before DailyArc?", "What made you try a habit tracker now?", "What would make you stop using this?" Map responses to persona hypotheses. If <3 participants match a persona's predicted behavior, flag for investigation. **Post-launch validation:** (1) cohort analysis comparing actual usage patterns to predicted persona behaviors, (2) monthly 5-participant usability interviews starting Week 2 post-launch, (3) 14-day diary study (see Research Protocol below).

**Rapid prototype test (MVP cut line, Week 5 — BLOCKING for onboarding changes):** 3 participants, unmoderated via Maze or UserTesting, 20 minutes each. Test: (a) time-to-first-log, (b) energy picker discoverability (target: 100% without prompting), (c) onboarding Page 1 comprehension and completion. If energy picker discoverability <60%, redesign before launch.

**Persona 1 — "Intentional Improver" (Primary, est. 60% of users)**
- Age 22-35, health-conscious, uses Apple Health
- **Job-to-be-Done:** "When I feel like my health habits are scattered and ineffective, I want to see evidence that my efforts are paying off, so I can maintain motivation through proof rather than willpower."
- **Current behavior:** Uses Apple Health passively, has tried 2-3 habit apps (Streaks, Habitica), abandoned them within 2 weeks due to complexity or subscription fatigue
- **Switching trigger:** Discovers DailyArc through "habit tracker privacy" search or Reddit recommendation
- **Anxieties:** "Will this be another app I abandon?", "Is my mood data really private?"
- Pain point: Tried other apps but found them too complex or subscription-heavy
- Conversion trigger: Hits 3-habit limit within first week, wants to track more
- Engagement pattern: Daily morning/evening check-ins, values streaks

**Persona 2 — "Curious Tracker" (Secondary, est. 25% of users)**
- Age 18-28, data-curious, wants to see patterns
- **Job-to-be-Done:** "When I notice my mood has been low for a week, I want to understand what I've been doing differently, so I can make intentional changes instead of guessing."
- **Current behavior:** Journals sporadically in Notes app, no structured tracking. May use Daylio but finds it "just mood logging" without actionable insights
- **Switching trigger:** Sees the insight teaser ("On exercise days, mood averages 4.2") in App Store screenshots or a friend's share card
- **Anxieties:** "Is the data actually meaningful with so few data points?", "Will I stick with it long enough to get insights?"
- Pain point: Logs mood sporadically but never connects it to behavior
- Conversion trigger: Sees correlation insights teaser, wants the full picture
- Engagement pattern: Irregular at first, deepens after seeing first insight

**Persona 3 — "Simple Streaker" (Tertiary, est. 15% of users)**
- Age 30-50, wants one simple thing tracked reliably
- **Job-to-be-Done:** "When I'm trying to build a single important habit like daily exercise, I want a dead-simple counter that celebrates my consistency, so I can feel accountable without being overwhelmed."
- **Current behavior:** Paper tally marks, calendar X's, or Apple Reminders. Has actively avoided complex habit apps
- **Switching trigger:** Recommendation from a friend or "simple habit tracker" search
- **Anxieties:** "Will this try to upsell me constantly?", "Is this going to be another notification-heavy app?"
- Pain point: Over-featured apps with too many decisions
- Conversion trigger: Rarely converts — happy with 1-3 free habits
- Engagement pattern: Single daily check-in, values simplicity over features

**Cross-cultural UX research plan (Phase 1 localization markets):**
- Before Phase 1 market launch (DE, JP, PT-BR), conduct 3-5 moderated remote usability sessions per market (9-15 total). Focus on: onboarding comprehension, mood scale interpretation (do emoji faces carry the intended emotional weight?), notification tone reception ("compassionate" may read as patronizing in some cultures), and privacy messaging effectiveness (on-device may be a stronger differentiator in DE than JP).
- **Recruitment:** Use UserTesting.com international panels (supports DE/JP/PT-BR with local-language participants). Budget: ~$50-75/participant = $450-1,125 total. Sessions conducted in local language; use UserTesting's built-in moderation tools for unmoderated sessions, or hire a local moderator for moderated sessions ($200-400 per market via Upwork).
- **Timeline:** Complete before Phase 1 localized App Store listing goes live. If Phase 1 launches at Month 2 post-launch, recruit by Month 1.5.
- Add cultural adaptation notes to localization plan per market. If mood emoji interpretation differs significantly, consider locale-specific emoji sets.
- A/B test notification tone variants by locale using existing experiment infrastructure.

**Interview failure criteria and pivot triggers:**
- If 5+ of 8 interviewees report the same critical barrier (e.g., "I don't understand what correlations are," "the mood scale feels too simple"), escalate to a design review before launch. Threshold: same issue cited by >60% of participants = BLOCKING design change.
- If persona distribution in interviews doesn't match predictions (e.g., 0 "Curious Trackers" in 8 interviews), flag that persona for re-evaluation — do not build premium features targeting a persona that doesn't appear in the wild.
- Document all findings in a shared "Research Findings" document; review with any future collaborators before v1.1 scope decisions.

**Diary study compensation (reconciled):** $25 App Store gift card for full completion (14 daily entries + exit interview). $15 for partial completion (≥10 of 14 days). Budget: $250-300 for 10 participants. **Over-recruit by 50%** (recruit 15, expect 10 completions) to account for dropout. This is the authoritative compensation figure.

**Monitoring threshold sample size requirements:**
- Do NOT act on Day 7 retention until 200+ users have reached Day 7
- Do NOT act on premium conversion until 500+ installs
- Do NOT declare A/B test winners until pre-computed N reached (per experiment table)
- For first 4 weeks, treat metrics as directional signals; rely on qualitative data (TestFlight feedback, diary study, support emails) for decisions
- Add confidence intervals to all KPI targets in post-launch dashboards

### Fogg Behavior Model Mapping (B = MAP)

DailyArc's core loop mapped to BJ Fogg's Behavior Model: Behavior = Motivation × Ability × Prompt.

| Loop Stage | Motivation | Ability | Prompt |
|-----------|-----------|---------|--------|
| First log | Onboarding value props ("see how habits shape mood") | 1-tap habit logging, pre-selected templates | Onboarding CTA, activation recovery notification |
| Daily logging | Streak maintenance, curiosity about patterns | Auto-save on tap, mood = 1 emoji | Morning/evening notifications, widget glanceable state |
| Insight unlock | "What habits make me happier?" curiosity gap | 14 days of passive data collection | Day 14 celebration + insight teaser notification |
| Premium conversion | Full insights access, unlimited habits | One-tap IAP, no subscription friction | Paywall at 3-habit limit or insight teaser view |
| Long-term retention | Badge collection, year-in-review, identity | Habitual (minimal cognitive load) | Weekly summary, milestone celebrations, rare greetings |

**Design implications:** When engagement drops, diagnose which factor is weakest. Low motivation → improve celebration/reward variety. Low ability → reduce taps, improve Today View. Low prompt → optimize notification timing/copy.

**Fogg diagnostic framework (use when a specific metric underperforms):**
| Symptom | Likely Weak Factor | Diagnostic Signal | Fix |
|---------|-------------------|-------------------|-----|
| High install, low Day 1 | Ability | Time-to-first-value > 120s | Simplify onboarding, reduce first-tap friction |
| Day 1-3 drop-off | Prompt | Notification opt-in < 50% | Test in-app prompts, optimize permission request timing |
| Day 7-14 drop-off | Motivation | Celebration engagement < 30% | Vary rewards, add Day 10/12 progress signals |
| High engagement, low conversion | Motivation (for payment) | Paywall view rate high, tap-through low | Test price, copy, timing |
| Post-Day-30 decline | Prompt (habit decay) | Weekly summary open rate declining | Vary notification copy, add new content types |

### Research Protocol: 14-Day Diary Study (Post-Launch, v1.0.1)

**Objective:** Understand real-world usage patterns, emotional responses to celebrations/streak loss, and unmet needs during the critical Day 1-14 activation window.

**Method:**
- **Participants:** 8-12 users recruited from TestFlight beta (mix of Persona 1/2/3, diverse demographics)
- **Duration:** 14 consecutive days (covers activation window + insight unlock)
- **Daily prompt:** 2-minute end-of-day survey via Typeform/Google Forms (not in-app — reduces bias): "What did you log today?", "How did logging make you feel?", "Anything confusing or frustrating?", "Screenshot anything notable"
- **Exit interview:** 20-minute moderated video call on Day 15. Semi-structured: "Walk me through your daily routine with the app", "What surprised you?", "What almost made you stop using it?", "Show me your Stats tab — what do you see?"

**Compensation:** $25 App Store gift card per participant who completes all 14 daily entries + exit interview. Budget: $250-300 for 10 participants. Partial completion (≥10 of 14 days): $15 gift card.

**Deliverables:**
- Affinity-mapped themes from daily entries
- Journey map of emotional highs/lows across 14 days
- Day 3-14 "motivation valley" validation (does it exist? what triggers re-engagement?)
- 5-7 prioritized improvement recommendations for v1.1
- **SUS (System Usability Scale) questionnaire:** Administer the standard 10-item SUS at the exit interview. Target score: ≥72 (above average). If <68, prioritize usability fixes over new features in v1.1. SUS provides a comparable benchmark against industry standards.

**Persona validation criteria:** After diary study, compare observed behavior patterns to the 3 defined personas. A persona is "validated" if ≥3 participants match its predicted usage pattern, engagement triggers, and conversion behavior. If a persona has 0 matches, retire it and define a new one based on observed clusters. Document discrepancies for the v1.1 persona refresh.

**Timeline:** Begin Week 3 post-launch (after initial bug fixes stabilize). Results inform v1.1 roadmap.

### Content Calendar & Marketing Strategy (Pre-Launch → Week 12)

| Week | Channel | Content | Goal |
|------|---------|---------|------|
| -4 (pre-launch) | Twitter/X, Reddit | "Building a habit tracker that respects your privacy" dev log thread | Build anticipation, developer community |
| -2 | Product Hunt draft | Prepare PH listing: tagline, screenshots, maker comment | Launch day readiness |
| -1 | TestFlight link | Share beta with niche communities (r/habits, r/quantifiedself) | Early feedback + reviews pipeline |
| Launch | Product Hunt, Twitter/X, Reddit | Launch post + "Why I built DailyArc" story | Initial installs, press coverage |
| +1 | App Store | In-App Event: "Start Your Arc" | Store visibility boost |
| +2-4 | Twitter/X | Weekly tips: "How habits shape mood" with DailyArc screenshots | Organic reach, social proof |
| +4-8 | Blog (dailyarc.app/blog) | "I tracked 30 days of habits — here's what I learned" | SEO, long-tail discovery |
| +8-12 | App Store | Seasonal promotional text update, PPO test results | Ongoing conversion optimization |

**Post-Week-12 recurring monthly content template:**
| Month | Channel | Content | Goal |
|-------|---------|---------|------|
| Every month | Blog | 1 SEO article from keyword mapping (rotate topics) | Long-tail organic discovery |
| Every month | Twitter/X | 2 tips/insights threads + 1 user story (with permission) | Engagement, social proof |
| Every month | App Store | Promotional text refresh (seasonal or feature-based) | Conversion optimization |
| Quarterly | Product Hunt | "What's new" collection or milestone update | Re-engagement, new audience |
| Quarterly | Reddit | r/habits value post with DailyArc mention (non-promotional) | Community presence |
| Seasonally | In-app | Seasonal greeting update + event copy refresh | Retention, freshness |
Content production cadence: ~4 pieces/month (1 blog + 2 social threads + 1 store update). Achievable for a solo developer. Scale to 8/month if content drives measurable installs (>50/month attributed).

**Content pillars:** (1) Privacy-first philosophy, (2) Habit-mood connection science, (3) User success stories (with permission), (4) Dev transparency / indie dev journey.

**Blog SEO keyword mapping (dailyarc.app/blog):**
| Blog Topic | Target Keywords | Search Intent |
|-----------|----------------|---------------|
| "How habits affect mood" | habit mood connection, mood tracking science | Informational |
| "Building a streak that lasts" | habit streak tips, how to keep a streak | Informational |
| "Privacy-first habit tracking" | private habit tracker, no account habit app | Transactional |
| "30-day habit challenge" | 30 day habit challenge, habit building guide | Informational/Navigational |
| "Habit tracker comparison" | best habit tracker iPhone, habit app review | Transactional |
Each post targets 1 primary keyword (in title + H1) and 2-3 secondary keywords. Publish biweekly starting Week +4. Internal link to App Store listing in every post.

**Email drip sequence (post-install, opt-in via onboarding or Settings):**
- Day 0: "Welcome to DailyArc" — quick start guide, 3 tips for first week
- Day 3: "Your first 3 days" — celebrate consistency, preview Day 7 badge
- Day 7: "One week in!" — share card prompt, preview mood insights
- Day 14: "Your insights are ready" — explain correlation feature, premium CTA
- Day 30: "30-day arc" — recap + invite to share story
Delivery: via email service (Buttondown/Mailchimp, free tier). Collect email optionally during onboarding Page 3 or Settings. Never required. Unsubscribe in every email.

**Email segmentation (free vs premium branches):**
- **Free users:** Days 0, 3, 7, 14 follow the standard sequence above. Day 14 email emphasizes premium value with soft CTA. Day 21 (free-only): "Your arc is growing — unlock unlimited habits and full insights." Final free-specific email. Day 30 follows standard sequence.
- **Premium users:** Days 0, 3, 7 follow standard sequence. Day 14: "Your insights are live — here's how to read them" (educational, no CTA). Day 21: "Power user tips — export your data, explore correlations." Day 30: standard recap.
- **Premium onboarding email:** Sent immediately on upgrade (any day): "Welcome to the full arc" — highlights all premium features with usage tips. Replaces the next scheduled drip email to avoid double-send.
- **Sunset sequence (inactive 60+ days):** Day 60: "Your arc is waiting — your data is safe." Day 90: "Final check-in — we'll stop emailing after this." Mark as inactive, stop all drip emails. Re-activate if user opens app.
- Tag users in email service with `tier: free|premium` and `last_active: date` for segmentation.

**Content repurposing strategy:** Each blog post spawns: (1) Twitter/X thread (key takeaways), (2) Reddit post (r/habits, r/quantifiedself — value-first, not promotional), (3) App Store promotional text update (if seasonal), (4) In-app insight card copy (if relevant to feature). One piece of content → 4 distribution channels.

**Content performance KPIs (track monthly):**
| Metric | Target | Tool |
|--------|--------|------|
| Blog organic sessions | 500/month by Month 6 | Google Analytics |
| Blog → App Store click-through | ≥5% | UTM tracking in App Store Connect |
| Twitter/X impressions per thread | ≥1,000 | Twitter Analytics |
| Reddit post upvotes (avg) | ≥10 per post | Manual tracking |
| Email open rate | ≥40% | Buttondown/Mailchimp |
| Email click-through rate | ≥8% | Buttondown/Mailchimp |
| Share card → install attribution | Track via `ct` parameter | App Store Connect |
**Action thresholds (all KPIs):**
- Blog organic sessions <100/month by Month 6 → pivot to SEO-focused topics (keyword research, competitor gap analysis); consider guest posting on productivity blogs.
- Twitter impressions consistently <500 → reduce posting frequency to 2x/week (quality over quantity); test visual content (screenshots, progress charts).
- Reddit upvotes consistently <5 → adjust subreddit targeting or post format; focus on storytelling posts rather than product mentions.
- Share card install attribution <0.5% conversion → redesign card CTA or test different QR code placement.
Review monthly. If blog CTR <3% for 3 months, pivot content strategy (more listicles, fewer long-form). If email open rate <25%, test subject lines and send times.

---

## App Store Optimization

- **App Name:** DailyArc: Habit & Mood (30 char max — this is 23. Uses colon not em dash to avoid multi-byte char ambiguity. "Tracker" removed — it is an extremely common indexed stem covered by competitors, and the subtitle compensates with "Log".)
- **Subtitle:** Streaks, Stats & Wellness Log (30 char max — this is 29. Avoids duplicating ANY word from title: "DailyArc"→"daily", "Habit"→"habit", "Mood"→"mood", "Tracker"→"tracker" are all already indexed. Adds unique keywords: "streaks", "stats", "wellness", "log".)
- **Primary Category:** Health & Fitness
- **Secondary Category:** Lifestyle
- **Price:** Free (with one-time IAP displayed as `product.displayPrice`)
- **Content Rating:** 4+ (no objectionable content, health data stays on-device)

### Keywords (100 characters max, comma-separated, no spaces after commas)
```
selfcare,routine,health,productivity,goals,diary,planner,improvement,mental,journal,checklist
```
- **DO NOT use:** meditation, mindfulness (misleading — this is not a meditation app), competitor names
- **Keyword strategy:** Apple indexes title, subtitle, and keyword field separately — never duplicate words across them (including stems). Title covers: "DailyArc", "habit", "mood", "tracker". Subtitle covers: "streaks", "stats", "wellness", "log". Keywords field fills remaining high-volume terms. Removed: "tracker" (in title), "log" (in subtitle), "wellness" (in subtitle — direct duplicate), "streak" (stem of "streaks" in subtitle — Apple does basic stemming), "wellbeing" (≈"wellness"), "healthy" (stem overlap with "health" — Apple does basic stemming). Added: "journal", "checklist" (high-volume complementary terms). Changed "self care" to "selfcare" (Apple treats spaces as separators). Total: 93 characters (under 100-char limit). 20+ unique indexed keywords across all three fields.
- **NOTE:** Apple does NOT index the iOS App Store description for search. The description's sole purpose is conversion, not ranking. Do not keyword-stuff the description.

**Competitor Keyword Gap Analysis:**
| Keyword | DailyArc indexed? | Daylio | Streaks | Habitify | Opportunity |
|---------|-------------------|--------|---------|----------|-------------|
| "mood tracker" | ✓ (title) | ✓ | ✗ | ✗ | High — compete directly with Daylio |
| "habit streaks" | ✓ (subtitle) | ✗ | ✓ | ✓ | Medium — differentiate with mood connection |
| "self care" | ✓ (keywords) | ✗ | ✗ | ✗ | High — underserved by competitors |
| "wellness log" | ✓ (subtitle) | ✗ | ✗ | ✗ | High — unique positioning |
| "privacy habit" | ✓ (implied) | ✗ | ✗ | ✗ | Very high — no competitor owns this space |
Gaps to target in v1.0.1 keyword rotation: "daily journal", "self improvement", "habit journal".

**Apple Search Ads Strategy (v1.0.1, $50-100/month budget):**
- **Campaign 1 — Brand defense:** Bid on "DailyArc" to protect brand searches. Low CPA, high conversion.
- **Campaign 2 — Category:** Bid on "habit tracker", "mood tracker" (broad match). Target CPA: <$2.00. Route to CPP 1 (mood) or CPP 2 (streaks) based on search term.
- **Campaign 3 — Competitor:** Bid on competitor names (Daylio, Streaks, Habitify). Target CPA: <$3.00. Route to CPP 3 (privacy-first). Note: higher CPA but higher-intent users.
- **Negative keywords (add to all campaigns):** "free", "game", "RPG", "social", "group", "team", "business", "enterprise", "CRM", "project management". These prevent wasted spend on irrelevant searches. Review Search Ads search term report weekly and add new negatives as needed.
- **Measurement:** Track tap-through rate (TTR) and conversion rate (CR) per ad group weekly. Pause keywords with CPA > $5.00.

**Review solicitation strategy (SKStoreReviewController timing):**
Apple allows up to 3 system prompts per 365-day period. Optimal trigger moments (listed in Review Solicitation section above): after 7-day streak, after insight unlock, after 100-day milestone. **Additional soft-ask surface:** After a user taps "Nice!" on a badge ceremony, show a subtle "Enjoying DailyArc?" row with "Rate on App Store" link (not system prompt — unlimited uses). This captures positive sentiment at the emotional peak without consuming system prompt quota.

**Seasonal keyword rotation plan:**
| Season | Swap Keywords | Rationale |
|--------|-------------|-----------|
| New Year (Dec-Jan) | Add "new year goals", "resolution tracker" | Seasonal search spike |
| Spring (Mar-Apr) | Add "spring habits", "fresh start" | Seasonal motivation |
| Back to school (Aug-Sep) | Add "student planner", "routine builder" | Student demographic spike |
| Year-end (Nov-Dec) | Add "year review", "annual habits" | Reflection searches |
Rotate keywords 1-2 weeks before each season. Keep core keywords stable.

### App Store Description (4000 char max)
**Opening line (most important — only first 3 lines visible before "more"):**
"Track your habits. Log your mood. See the connection. DailyArc reveals which habits actually make you happier — with data that stays on your device."

**Body (after opening paragraph):**

DailyArc connects what you do with how you feel. Track your daily habits with a single tap, log your mood in seconds, and watch as patterns emerge over time.

Build streaks that keep you motivated. See your consistency on a beautiful year-long heat map. When you hit milestones — 7 days, 30 days, 100 days — celebrate with badges and shareable streak cards.

Go deeper with premium insights. Discover which habits lift your mood and which drain your energy. "On exercise days, your mood averages 4.2" — real patterns from your real data, computed entirely on your device.

Sync with Apple Health to auto-log workouts, steps, sleep, and mindful minutes. Your health data stays on your device — not now, not ever shared with anyone.

Privacy is not a feature. It is the architecture. DailyArc has no accounts and no tracking. Your habit and mood data lives on your iPhone — we never see it.

One payment. Yours forever. No subscriptions. No recurring charges. No ads. Just a thoughtful tool that gets better the more you use it.

• Track habits with one tap — auto-saves instantly
• Log mood with 5 emoji scale + energy + activity tags
• Streaks, milestones, and badges celebrate your consistency
• Heat map calendar shows your year at a glance
• Mood-habit correlations reveal what makes you happier (Premium)
• HealthKit sync for workouts, steps, sleep, mindful minutes
• Home screen and lock screen widgets
• Export your data anytime (JSON free, CSV premium)
• No accounts. No servers. 100% on-device.

Download DailyArc free today. Your arc starts now.

**Full localized descriptions (required for Phase 1 markets — not just opening paragraph):**
- **German:** Translate ALL bullet points, privacy paragraph, pricing paragraph, and CTA. Closing CTA: "Lade DailyArc kostenlos herunter. Dein Arc beginnt jetzt."
- **Japanese:** Translate ALL bullet points, privacy paragraph, pricing paragraph, and CTA. Closing CTA: "DailyArcを無料でダウンロード。あなたのアークが始まります。"
- **Brazilian Portuguese:** Translate ALL bullet points, privacy paragraph, pricing paragraph, and CTA. Closing CTA: "Baixe o DailyArc gratuitamente. Seu arco começa agora."
- Use professional translation (not machine translation) for all App Store copy — it is conversion-critical. Budget: ~$150-300 for 3 locales.

**DO NOT mention competitor names** in App Store listing or paywall — Apple may reject, and it's poor brand practice.

### Screenshot Strategy (6.7" and 6.1" required, up to 10 screenshots)
1. **"Build habits that stick"** — Today view with mood emojis + habit circles + confetti celebration
2. **"See your year at a glance"** — Heat map calendar showing 12 months of consistency
3. **"Track your streaks"** — Stats with streaks (🔥) + completion rings + trend charts
4. **"Discover what makes you happier"** — Insights: "On exercise days, your mood averages 4.2"
5. **"One price. Yours forever."** — Paywall: "$5.99 once. No subscriptions." (marketing can show USD)
6. **(Optional) "Your habits, on your home screen"** — Widget showcase (lock screen + home screen widgets)
7. **(Optional) "Ready in 30 seconds"** — Onboarding flow

**Screenshot design tips:** Use device frames, large readable text overlays, consistent color scheme matching app accent. Show real-looking data (not obviously fake).

### App Preview Video (optional, 15-30 seconds — 20-30% conversion lift per Apple data)
**Duration:** 25 seconds (sweet spot: long enough to show value, short enough to retain attention).
**Shot list (all captured on-device, no external editing overlays):**
1. (0-3s) App icon → launch → Today View appears with greeting
2. (3-8s) Tap mood emoji (show selection animation + energy picker) — demonstrates mood logging speed
3. (8-14s) Tap 3 habits to completion (show count increment, confetti on last) — demonstrates one-tap logging
4. (14-19s) Swipe to Stats tab → heat map fills in, streak counter visible — demonstrates long-term value
5. (19-23s) Scroll to Insights → "On exercise days, mood averages 4.2" card — demonstrates premium value
6. (23-25s) End card: "DailyArc" wordmark + "Your arc starts now." tagline
**Audio:** Use app's own sound design (tap sounds, completion chime, celebration fanfare) — no voiceover, no music. Apple requires app audio only.
**Localization:** Capture separate videos for DE/JP/PT-BR with localized UI strings (Phase 2, after in-app localization).
**Technical:** Record at native resolution (1290×2796 for 6.7", 1179×2556 for 6.1"). Portrait orientation only. H.264 or HEVC. Submit both device sizes.

### In-App Events (App Store Connect)
Schedule in-app events to boost visibility in search results and editorial placements:
- **Launch Week:** "Start Your Arc" — new user onboarding event highlighting the free tier experience
- **New Year (Jan 1-7):** "New Year, New Arc" — seasonal habit-building event with curated templates
- **Mental Health Awareness (May):** "Mood + Habits: See the Connection" — insight feature spotlight
- **Back to School (Sep):** "Build Your Routine" — student-focused habit templates
- **Required In-App Event fields (per App Store Connect):**
  - Event name: ≤30 characters
  - Short description: ≤50 characters
  - Long description: ≤120 characters
  - Event card image: 1920×1080px, no text in image (Apple guidelines)
  - Badge: optional (use for New Year and seasonal events)
  - Deep link: URL scheme to relevant app section (e.g., `dailyarc://today`)
  - Start/end dates: scheduled in App Store Connect ≥2 weeks in advance
- Event cards use app accent gradient (Sky→Indigo), 1920×1080 event card image
- Link each event deep link to relevant app section (onboarding, insights, templates)
- **Scheduling:** Set up all 4 events in App Store Connect at launch. Events appear in search results and editorial placements, providing free visibility boosts.
- Schedule 4-6 events per year for consistent App Store presence

### Custom Product Pages (CPPs)
Create 2-3 custom product pages targeting different user intents:
- **CPP 1 — "Mood Tracker":** Lead screenshot = Insights view. Subtitle emphasis on mood-habit correlation. Target: users searching mood-related keywords.
- **CPP 2 — "Streak Tracker":** Lead screenshot = Today view with streak fire. Subtitle emphasis on streaks and consistency. Target: users searching streak/habit keywords.
- **CPP 3 — "Privacy-First":** Lead screenshot = Settings/privacy view. Subtitle emphasis on on-device, no-subscription. Target: users searching privacy-focused alternatives.
- Each CPP has unique screenshots (reordered from main set), localized per Phase 1 market.
- Use Apple Search Ads to drive traffic to each CPP and measure conversion rate per variant.

**Localized screenshot A/B test plan:**
- **DE market (Week 6):** Test whether "Entdecke, was dich glücklicher macht" (insight-led) or "Gewohnheiten, die bleiben" (habit-led) converts better as the first screenshot text overlay.
- **JP market (Week 8):** Test whether emoji-heavy screenshots or text-heavy screenshots convert better (Japanese App Store users respond differently to visual density).
- **PT-BR market (Week 10):** Test "Um preço. Para sempre." emphasis (price-led) vs "Descubra o que te faz mais feliz" (insight-led) as primary screenshot CTA.
- Each test runs for minimum 7 days, requires 90% statistical confidence. Use App Store Connect PPO for the default product page; use CPPs for intent-targeted testing.

### Product Page Optimization (PPO)
A/B test product page elements via App Store Connect (no code change):
- **Test 1 (Week 2 post-launch):** Screenshot order — lead with Today view vs lead with Insights view. Metric: conversion rate (impressions → installs).
- **Test 2 (Week 6):** Icon variant — current gradient arc vs solid-color arc. Requires 90-day wait between icon tests.
- **Test 3 (Week 10):** Subtitle wording — current vs "Track Habits, Discover Insights."
- Minimum 7 days per test, target 90% statistical confidence before declaring winner. **Decision criteria:** (1) Minimum sample: 100 impressions per variant before evaluating. (2) Wait for full 7 days even if significance reached early (weekly cycles affect behavior). (3) Primary metric must be statistically significant (p < 0.10, one-tailed). (4) If no winner after 21 days, keep the control and test a more different variant. (5) Document every test result in a shared "PPO Test Log" for institutional memory.

### Review Solicitation
Apple allows up to 3 system review prompts per 365-day period (and may throttle further). Trigger at 3 strategic moments for maximum positive sentiment:
1. **After first 7-day streak** — user has just achieved a meaningful milestone
2. **After first insight unlock (Day 14+)** — user has experienced premium value
3. **After 100-day milestone** — deeply engaged, likely to rate highly
Track prompt count and dates in `@AppStorage("reviewPromptDates")` (comma-separated ISO dates). Show max 3 per year. Use SwiftUI `.requestReview()` — NOT deprecated `SKStoreReviewController`. Note: Apple's system throttles display frequency; multiple calls are safe.

### "What's New" Release Notes Template
Every App Store update is a re-engagement touchpoint. Template (adapt per release):
- **v1.0:** "Welcome to DailyArc! Track habits, log moods, and discover what makes you happier. Your habit and mood data stays on your device."
- **v1.0.x bug fixes (template):** "Small improvements for a smoother experience. Everything's running better than ever." Variants: "We squashed a few bugs so your streaks stay smooth." / "Under-the-hood tune-up — faster, steadier, better." / If specific fix matters to users: "Fixed [user-facing issue]. Plus general improvements for reliability."
- **v1.x feature updates:** Lead with the user benefit, not the feature name. "Now you can [benefit]. Plus [smaller improvement]."
- **Tone:** Match the app's warm, encouraging voice. Never technical ("fixed CoreData migration"). Always human ("Your data loads faster now").

### Promotional Text (170 chars, updatable without new build)
Update seasonally and for milestones (rotate every 2-4 weeks):
- **Launch:** "See how your habits shape your mood. 100% on-device. One price, yours forever."
- **New Year:** "Start your arc. See where it takes you — no subscription, no pressure."
- **Post-milestone (1K downloads):** "Join thousands building better habits. Your data stays private. Always."
- **Feature update:** "NEW: [Feature benefit in human language]. Plus everything you love — still private, still yours."
- **Mental Health Awareness (May):** "Your mood tells a story. DailyArc helps you read it — privately, on your device."
- **Back to school (Sep):** "New routines start here. Track habits, build streaks, own your data."
- **Summer:** "Summer habits, tracked. See which ones make you feel your best."

**Localized promotional text (launch only — rotate translations with each seasonal update):**
- **German:** "Entdecke, wie deine Gewohnheiten deine Stimmung beeinflussen. 100% auf deinem Gerät. Einmalzahlung."
- **Japanese:** "習慣が気分にどう影響するか発見しよう。100%デバイス上で完結。買い切り。"
- **Brazilian Portuguese:** "Descubra como seus hábitos influenciam seu humor. 100% no seu dispositivo. Pagamento único."

**Screenshot text overlays (aligned with Screenshot Strategy headlines, localized per market):**
1. "Build habits that stick" / "Gewohnheiten, die bleiben" / "続く習慣をつくろう" / "Crie hábitos que duram"
2. "See your year at a glance" / "Dein Jahr auf einen Blick" / "一年を一目で" / "Veja seu ano de relance"
3. "Track your streaks" / "Verfolge deine Serien" / "連続記録を追跡" / "Acompanhe suas sequências"
4. "Discover what makes you happier" / "Was macht dich glücklicher?" / "幸せの理由を発見" / "Descubra o que te faz mais feliz"
5. "One price. Yours forever." / "Einmal zahlen. Für immer." / "一度の購入、ずっとあなたの" / "Um preço. Para sempre."

### Localization Strategy (Free 40%+ Market Expansion)

**Phase 1 (v1.0 — App Store listing only, zero code change):**
Localize App Store metadata for top 4 markets by iOS revenue:
| Market | Language | Localized title | Localized subtitle |
|--------|----------|-----------------|-------------------|
| US/UK/AU | English | DailyArc: Habit & Mood | Streaks, Stats & Wellness Log |
| Germany | German | DailyArc: Gewohnheits-Tracker | Streaks, Statistiken & Wohlbefinden |
| Japan | Japanese | DailyArc: 習慣&気分トラッカー | 連続記録・統計・セルフケアログ |
| Brazil | Brazilian Portuguese | DailyArc: Hábitos e Humor | Sequências, Estatísticas e Bem-estar |

Localize keywords (100 chars per locale), description opening paragraph, and screenshot text overlays. App name stays "DailyArc" in all markets (brand consistency).
**Note:** FR and ES deferred to Phase 2 — Brazil (PT-BR) has higher iOS revenue and lower ASO competition for habit tracker keywords.

**Localized description opening paragraphs (first 3 visible lines — conversion-critical):**
- **German:** "Verfolge deine Gewohnheiten. Logge deine Stimmung. Erkenne den Zusammenhang. DailyArc zeigt dir, welche Gewohnheiten dich wirklich glücklicher machen — deine Daten bleiben auf deinem Gerät."
- **Japanese:** "習慣を記録。気分をログ。つながりを発見。DailyArcは、どの習慣があなたを幸せにするかを明らかにします — データはあなたのデバイスに保存されます。"
- **Brazilian Portuguese:** "Registre seus hábitos. Anote seu humor. Veja a conexão. O DailyArc revela quais hábitos realmente te fazem mais feliz — seus dados ficam no seu dispositivo."

**Localized keyword fields (100 chars max each, comma-separated):**
**RULE: ZERO duplication with title/subtitle words (including stems). Apple indexes title+subtitle separately — duplicating wastes keyword slots.**
- **German:** `Stimmung,Routine,Gesundheit,Tagebuch,Selbstfürsorge,Produktivität,Ziele,Fortschritt,Tracker,Laune` (97 chars. Removed: Gewohnheit [stem of title], Wellness→Wohlbefinden [in subtitle], Streaks [in subtitle], Achtsamkeit [misleading — not a meditation app]. Added: Tracker [high-volume DE search term], Laune [mood synonym, indexed separately from Stimmung])
- **Japanese:** `ルーティン,健康,日記,目標,生産性,毎日,進捗,継続,自己管理,習慣化,体調管理,気分日記,メンタルヘルス,ライフログ,自己改善,健康管理` (82 chars. Removed: 習慣/気分 [in title], ウェルネス/連続記録→セルフケア [in subtitle], マインドフルネス [misleading — not a meditation app]. Added high-value compound terms: 習慣化 [habit formation], 体調管理 [health management], 気分日記 [mood diary], メンタルヘルス [mental health], ライフログ [life log], 自己改善 [self-improvement], 健康管理 [wellness management]. Note: 習慣化 is a distinct compound word from 習慣 and is indexed separately by Apple.)
- **Brazilian Portuguese:** `rotina,saúde,diário,produtividade,metas,autocuidado,progresso,motivação,constância,registro,mente,humor` (99 chars. Removed: hábito [stem of title], bem-estar [in subtitle], sequência [stem of subtitle]. Covers high-volume PT-BR terms for habit/wellness tracking.)
Verify each fits within 100-char limit before submission. Maximize toward 100 chars per locale.

**Phase 2 (v1.1 — in-app localization):**
- Extract all user-facing strings to `Localizable.strings` using `NSLocalizedString` / String(localized:)
- Localize onboarding, notifications, empty states, button labels
- Do NOT localize habit template names (emoji-first design is universally readable)
- Use `.environment(\.locale)` for previews during development

**In-app string preparation for v1.0:** Even without Phase 2, use `String(localized:)` wrappers from day 1 so all strings are extraction-ready. Zero runtime cost, massive time savings when localization begins.

---

## Pre-Launch Checklist

**Phase 1: Before Coding Starts (Week 0)**
- [ ] CI/CD: Xcode Cloud or GitHub Actions configured per **Rule 37** (Day 1 prerequisite) — on every PR: build + run XCTest + SwiftLint. On merge to main: archive + upload to TestFlight automatically. Eliminates manual build/upload friction for rapid iteration. Verify: pipeline runs green before Step 1 code begins.
- [x] TelemetryDeck Data Processing Agreement (DPA) signed — **BLOCKING PREREQUISITE for Step 1** (not just pre-launch). Must be completed before any analytics code is written. Required by GDPR Article 28. Standard on TelemetryDeck's dashboard.
- [ ] Domain registered (dailyarc.app or dailyarcapp.com)
- [ ] Social handles claimed (@DailyArcApp)
- [ ] Support email configured
- [ ] Trademark search for "DailyArc" filed (USPTO TEAS, ~$250) — **takes 4-6 months for initial response; file Week 0, can ship while pending**
- [ ] App Group configured for widget data sharing ("group.com.dailyarc.shared")

**Phase 2: Before MVP TestFlight (Week 5)**
- [ ] **DPIA (Data Protection Impact Assessment) — BLOCKING PREREQUISITE for Step 5b.** Must be completed BEFORE CorrelationEngine implementation begins (GDPR Article 35 — required before processing begins, not just before launch. Complete during Week 4 at the MVP cut line, before CorrelationEngine implementation in Week 5). CorrelationEngine constitutes automated profiling of health-related data per Art. 35(3)(a). The DPIA must contain four minimum components per Art. 35(7):
  - **(a) Systematic description:** DailyArc processes mood scores (1-5), energy scores (1-5), habit completion data, and HealthKit metrics on-device only. CorrelationEngine computes Pearson correlations between habits and mood. No data is transmitted off-device except anonymous analytics to TelemetryDeck (under DPA).
  - **(b) Necessity & proportionality:** Mood-habit correlation is the core premium value proposition; processing is proportionate to purpose. Minimum data collected (mood score, not free-text diary). Consent is granular (mood correlation consent separate, default OFF).
  - **(c) Risks to data subjects:** Primary risk: unauthorized device access exposing mood/health patterns. Mitigated by: iOS device encryption, no cloud sync, no server storage, SwiftData on-device only. Secondary risk: incorrect correlations influencing health decisions. Mitigated by: mental health disclaimer, significance testing, confidence qualifiers, "not medical advice" language.
  - **(d) Measures to address risks:** On-device-only architecture, GDPR Art. 9 explicit consent, granular consent withdrawal, complete data erasure, share card privacy guards, COPPA age gate.
  - Keep DPIA on file; not published but available for supervisory authority review. No DPO required under Art. 37 (not a public authority, not large-scale systematic monitoring).
- [ ] Privacy policy hosted at permanent URL and linked in Settings + App Store Connect
- [ ] Mental health disclaimer included in privacy policy and Settings screen
- [ ] Age verification gate functional (DOB picker, blocks <13, COPPA compliant)
- [ ] GDPR consent flow functional (required + optional toggles)
- [ ] Usability testing at MVP cut line (after Step 4, Week 4): 3-5 participants testing first habit log, mood check-in, and stats interpretation — **recruit by Week 3 (1-2 week lead time)**

**Phase 3: Before External Beta (Week 14)**
- [ ] App Store Privacy Nutrition Labels configured in App Store Connect (see Step 8 §8) — **includes email as "Data Linked to You" if email collection is active**
- [ ] **Buttondown DPA signed (GDPR Art. 28) — BLOCKING PREREQUISITE before exporting any collected emails.** Required because email addresses are shared with Buttondown for weekly summary delivery.
- [ ] **All placeholder fields in Privacy Policy and Terms of Service replaced** with actual legal entity information ([Your Legal Name], [Registered Address], [Country], [Your jurisdiction])
- [ ] NSHealthShareUsageDescription string in Info.plist
- [ ] App icon designed (arc/circle motif with accent color gradient)
- [ ] 6.7" and 6.1" screenshots prepared (minimum 5, see ASO section)
- [ ] App preview video (optional but recommended — 20-30% conversion lift)
- [ ] StoreKit tested in sandbox (purchase, restore, family sharing)
- [ ] VoiceOver audit complete (all views, all states)
- [ ] Dynamic Type tested at all sizes (accessibility inspector)
- *(Accessibility user testing — see Phase 3 above)*
- [ ] Dark mode audit complete (all habit colors resolve via colorIndex → palette light/dark hex)
- [ ] Reduced motion audit complete (confetti → static, animations → instant)
- [ ] Performance profiled (heat map <100ms, streak cache, widget reads, 365-day memory)
- [ ] TestFlight beta (minimum 5 external testers, 1 week) — see go/no-go criteria below
- [ ] All HealthKit entitlements configured in Xcode (HealthKit capability + Background Modes if using observer)
- [ ] Localized privacy policy versions for Phase 1 markets (DE, JP, PT-BR at minimum) — GDPR Art. 12(1) / LGPD Art. 9 require information be "intelligible" in the user's language — **allow 1-2 weeks for professional translation**
- [ ] **Accessibility user testing (1 participant minimum):** Recruit at least 1 VoiceOver or Switch Control user for a 30-minute moderated session — **recruit by Week 12 (harder to find than general testers)**
- [ ] GDPR Art. 30 records of processing activities maintained (purpose, data categories, recipients, retention, security measures)

**Phase 4: Before App Store Submission (Week 17-18)**
- [ ] Breach notification mechanism: emergency in-app banner via hosted `dailyarc.app/security.json` check on launch (static file, enables immediate notification independent of App Store review timelines). **Implementation:** On every `.scenePhase == .active`, fetch `dailyarc.app/security.json` (cached, 6-hour TTL, silent failure on network error — app continues normally). Schema: `{"breach": false, "message": "", "severity": "none"|"info"|"critical", "actionURL": "", "signature": ""}`. If `breach == true`, show non-dismissible banner at top of Today View with message and optional action link. This satisfies GDPR Art. 34 notification requirement without depending on App Store review cycle. **Integrity verification:** Add an HMAC-SHA256 signature field to the JSON payload, verified client-side with a hardcoded public key embedded in the app binary. This prevents a compromised hosting account from injecting false breach notifications. **Hosting:** Host on a zero-maintenance static provider (GitHub Pages or Cloudflare Pages) with HSTS and DNS CAA records. **Kill switch:** `dailyarc.app/status.json` (1-hour TTL) enables emergency feature disabling without an App Store update.
- *(Usability testing — see Phase 2 above)*
- [ ] Ensure `dailyarc.app` web properties either use no cookies/tracking or implement ePrivacy Directive cookie consent
- [ ] Cognitive accessibility audit: notification copy at 8th-grade reading level (Flesch-Kincaid), stats view progressive disclosure verified, onboarding instructions single-step clarity
- [ ] Widget extension target added with correct App Group
- *(Trademark, domain, social handles, support email — see Phase 1 above)*
- *(CI/CD and TelemetryDeck DPA — see Phase 1 above)*
- [ ] **Usability testing protocol (5 participants minimum):**
  - **Recruitment:** 5 participants from target demographic (adults 18-45 who currently track habits or want to). Mix: 2 existing habit tracker users, 2 new to tracking, 1 accessibility user (VoiceOver or Dynamic Type XXL). Recruit via TestFlight public link or UserTesting.com.
  - **Method:** Moderated remote (Zoom + screen share) or unmoderated (Maze/UserTesting with think-aloud). 30-minute sessions. Record screen + audio.
  - **Tasks and success criteria:**
    1. Onboarding completion + first habit creation (target: <2 min, <4 taps to first log)
    2. Daily logging flow for 3 habits (target: <10s per habit, <30s total)
    3. Mood check-in with energy (target: 100% discover energy picker without prompting)
    4. Stats interpretation (target: 80%+ correctly identify their best streak and mood trend direction)
    5. Paywall comprehension (target: 80%+ understand what premium adds vs free)
  - **Blocking threshold:** Fix any task with <70% success rate before App Store submission. Fix any task with <80% success rate before v1.1.
  - **Quantitative usability benchmarks (measure post-launch via TelemetryDeck):**
    * Time to first habit log (from onboarding complete): median <60s, p90 <120s
    * Time to complete daily logging (all habits + mood): median <30s for 3 habits
    * Task completion rate for mood logging: >95% (track via `mood_logged` / `today_view_opened`)
    * Task completion rate for Stats interpretation: >80% understand their streak (validated in usability test)
    * Error recovery rate: >90% of users who see an error successfully retry (track `error_retry_success`)
  - **Deliverable:** Findings summary with severity-ranked issues, video clips of failure moments, recommended fixes.
  - **Tools:** TestFlight + built-in iOS screen recording, or UserTesting.com/Maze for unmoderated. Maze provides heatmaps and misclick tracking for quantitative analysis.

### TestFlight Go/No-Go Criteria

**Must pass ALL before external beta:**
1. Zero crashes in 30 minutes of continuous use (Instruments + MetricKit)
2. All XCTest targets pass (unit + integration)
3. XCUITest smoke tests pass: onboarding flow, habit CRUD, mood logging, streak display, paywall purchase (sandbox), export JSON, widget renders
4. Memory usage <150MB after 365-day simulated dataset (DebugDataGenerator)
5. Heat map renders in <100ms (Instruments Time Profiler)
6. HealthKit authorization + backfill completes without crash (test with Health simulator data)
7. Dark mode: all screens visually audited (no unreadable text, no invisible elements)
8. VoiceOver: all screens navigable, no unlabeled elements
9. Privacy policy URL resolves and contains all 8 required sections
10. App Store Connect: all metadata, screenshots, and privacy labels configured

**Release Rollback Procedure:**
- **Failed release detection:** Monitor MetricKit crash-free rate within 4 hours of each App Store release. If crash-free rate drops below 99%, trigger rollback evaluation.
- **Rollback mechanism:** Submit the previous build to App Store Connect with expedited review request ("significant bug fix"). Apple typically reviews within 24 hours for critical fixes.
- **Emergency in-app kill switch:** Check `dailyarc.app/status.json` on each app launch (cached, 1-hour TTL). If `{"status": "degraded", "message": "...", "disableFeatures": ["insights"]}`, show banner and disable specified features. This provides immediate mitigation without waiting for App Store review.
- **Data migration rollback:** If a VersionedSchema migration fails for some users, the ModelContainer failure recovery path (repair/reset) handles this. Never ship a migration without testing on a copy of the previous version's database.
- **ML model versioning (v1.1):** When CoreML models are introduced, store model version in `@AppStorage("mlModelVersion")`. If a model produces worse predictions (measured via user engagement with suggestions), revert to the previous model version without an app update.

**App Store Rejection Contingency:**
- Common rejection reasons and pre-planned fixes:
  - Guideline 5.1.1 (Data Collection): verify privacy labels match actual data collection → run Privacy Report in Xcode
  - Guideline 5.1.2 (HealthKit): ensure HealthKit is not gated behind paywall → verified in spec
  - Guideline 3.1.1 (IAP): ensure all digital content uses IAP → only one IAP (premium unlock)
  - Guideline 2.1 (Crashes): ensure crash-free rate ≥99.5% from TestFlight telemetry
- Response time target: 24-48 hours for resubmission after rejection

---

## Development Timeline (Realistic)

**Week 0 (before coding):** Phase 1 pre-launch checklist — CI/CD, TelemetryDeck DPA, domain/social/trademark, pre-registration landing page at dailyarc.app/launch
**Week 1:** Step 1a — SwiftData models, schema versioning, `ModelContainer`, `DateHelpers`, `HabitColorPalette`
**Week 2:** Step 1b — `StreakEngine`, `DebouncedSave`, `DedupService`, `RuleEngine`, unit tests, performance baselines
**Week 3:** Step 2 — Today View with ModelContext.fetch, debounced auto-save, confetti, undo toasts. **Begin recruiting** 3-5 usability test participants for Week 5 MVP gate (1-2 week lead time).
**Week 4:** Step 3 — Habit form, templates, management, archive. **Complete DPIA** (blocking prerequisite for Step 5b).
**Week 5:** Step 4 — Stats tab, Canvas heat map, mood trend chart, progressive loading

> **--- MVP CUT LINE (Step 4 complete: 4–5 weeks) ---**
> At this point you have a fully functional habit + mood tracker with stats. Ship to TestFlight for early feedback while building premium features.
>
> **MVP Decision Gate (Week 5):** Before proceeding to premium features, evaluate:
> 1. **Rapid prototype test (3 participants, BLOCKING for onboarding changes):** Energy picker discoverability, time-to-first-log, onboarding Page 1 comprehension. If energy picker discoverability <60%, redesign before proceeding.
> 2. **Usability test (3-5 participants):** Can users complete first habit log in <2 min? Can users interpret stats correctly?
> 3. **Performance:** Cold launch <1.0s, heat map <100ms, memory <150MB on 365-day dataset.
> 4. **Stability:** Zero crashes in 30-minute continuous use session.
> 5. **Go/No-Go:** If any blocking issue found, fix before moving to Step 5. Document findings in TestFlight build notes.

**Week 6:** Step 5a — StoreKit 2, paywall, premium gates
**Week 7:** Step 5b — CorrelationEngine async, insights tab, bar charts (DPIA must be complete)
**Week 8:** Step 6a — Settings, export, in-app help system
**Week 9:** Step 6b — GDPR consent, COPPA age gate, notifications
**Week 10:** Step 7a — Onboarding, share cards (all 3 formats), badge ceremonies. **Begin influencer outreach** (10 messages to micro-influencers with TestFlight link).
**Week 11:** Step 7b — Widgets (small widget for v1.0; medium/large deferred to v1.0.1)
**Week 12:** Step 8a — HealthKit integration, HabitLogWriteActor, BackgroundTaskService. **Begin recruiting** accessibility tester (1+ VoiceOver/Switch Control user, harder to find — start early).
**Week 13:** Step 8b — Performance audit, dark mode polish, accessibility audit. **Begin** localized privacy policy translations (1-2 week lead time for DE/JP/PT-BR).
**Week 14:** TestFlight beta (minimum 5 external testers, 1 week). **Pre-launch validation interviews** (5-8 structured interviews with beta participants, BLOCKING). Usability testing protocol.
**Weeks 15-16:** Bug fixes from beta feedback, edge cases. Accessibility user testing session. Cross-cultural UX research (if Phase 1 localization launching with v1.0).
**Weeks 17-18:** Buffer / App Store submission prep / review response. All placeholder fields in Privacy Policy replaced.

**Total: 14–18 weeks** (realistic, accounts for step splits and thorough testing)

**Minimum shippable product (if behind schedule at Week 14):** Ship without widgets (Step 7b) and HealthKit (Step 8a). These can be added in v1.0.1 within 2 weeks post-launch. The core value (habit logging + mood logging + streak tracking + basic stats + insights) does not depend on them.

**Daily workflow guidance:** Each sub-step targets 4 days of implementation + 1 day of testing/polish. Day 1-2: core implementation of the step's primary deliverable. Day 3: secondary deliverables and edge cases. Day 4: integration with previous steps, UI polish. Day 5: unit tests, accessibility pass, manual QA against the step's milestone checklist.

**Scope freeze rule:** After Step 4 (MVP cut line), no new features may be added to v1.0 scope without dropping an existing feature of **equal or greater estimated effort** (see effort estimates in priority tier table below). To add a feature, document a "scope trade": (a) what's being added + estimated hours, (b) what's being dropped + estimated hours of the dropped item. The dropped item must have equal or greater hours. The whimsy section (Easter eggs, seasonal variants, sound synthesis specs) is P1/P2 and can be cut first if behind schedule.

**Priority tiers within Steps 5-8:**
| Step | P0 (must ship) | Est. Hours | P1 (should ship, cut if 1 week behind) | Est. Hours | P2 (nice to have, cut if any delay) | Est. Hours |
|------|---------------|-----------|---------------------------------------|-----------|--------------------------------------|-----------|
| 5a | StoreKit purchase, paywall, premium gates | 24h | Price anchoring copy, "Not now" warm dismissal | 8h | Paywall animation polish | 4h |
| 5b | CorrelationEngine, top-3 correlations, bar charts | 32h | Energy insights, activity insights | 12h | Scatter plots for multi-count habits | 8h |
| 6a | Notifications, JSON export (GDPR), consent flow, age gate | 28h | CSV export, notification aggregation | 10h | Reactivation reminders (Days 10-14) | 6h |
| 6b | GDPR settings, COPPA, in-app help | 20h | Device transfer guidance | 4h | FAQ article expansion | 4h |
| 7a | Onboarding 3 pages, tab navigation, share cards | 24h | Haptics, review solicitation | 8h | Easter eggs beyond 3 minimum | 6h |
| 7b | SmallStreakWidget (free), widget deep links | 20h | MediumTodayWidget, LargeStatsWidget | 12h | Seasonal widget accents | 4h |
| 8 | HealthKit queries, dark mode audit, privacy policy | 28h | Performance profiling, MetricKit | 12h | Sound design (can ship silent in v1.0) | 8h |

**Effort budget summary:** P0 total = ~176h (~4.4 weeks at 40h/wk). P1 total = ~66h (~1.7 weeks). P2 total = ~40h (~1 week). This validates the 14-18 week timeline: P0 alone fills Steps 5-8 (4 weeks core + margin), with P1/P2 filling polish weeks.

**Week 12+ operational plan (post-launch time allocation for solo developer):**
- Development (new features): 50% → reduces to 30% if support volume exceeds 20 emails/week
- Support (email, reviews): 20% → increases proportionally with user base
- Content/marketing: 15% (blog posts, social, keyword monitoring)
- Monitoring/analytics: 15% (daily dashboard checks first 2 weeks, then weekly)
- Transition triggers: at 1K DAU → hire part-time support; at 5K DAU → consider contracting for v1.1 features

**Post-launch triage priority order (when multiple issues compete):**
1. **P0 — Crashes/data loss:** Crash-free rate <99%, SwiftData corruption, streak data loss → hotfix same day
2. **P1 — Revenue blockers:** StoreKit failures, paywall not rendering, restore purchases broken → patch within 48h
3. **P2 — Retention blockers:** Broken notifications, HealthKit sync failures, widget not updating → patch within 1 week
4. **P3 — UX issues:** Visual glitches, copy errors, animation jank → batch into next scheduled release
5. **P4 — Feature requests:** New features from user feedback → evaluate for v1.1 backlog

**Financial Model (back-of-napkin, Year 1):**
| Scenario | Weekly installs | Year 1 installs | Premium conv. (5%) | Revenue (×$5.99) |
|----------|----------------|-----------------|--------------------|--------------------|
| Pessimistic | 50 | 2,600 | 130 | $779 |
| Base | 150 | 7,800 | 390 | $2,336 |
| Optimistic | 400 | 20,800 | 1,040 | $6,230 |
- **Breakeven analysis:** 9-11 weeks of solo dev time at opportunity cost of ~$15K-25K (depending on developer rate). Breakeven requires ~2,500-4,200 premium conversions, achievable in base/optimistic scenarios within Year 1-2.
- **LTV cap:** $5.99 (one-time purchase). No upsell, no subscription, no ads. Revenue is purely unit economics.
- **Key assumption:** 5% premium conversion at Day 7 based on Daylio/Streaks category benchmarks. If actual conversion is <3%, test price reduction or additional paywall surfaces before v1.0.2.

---

## Deferred to v1.1

- Watch app (WatchKit + WatchConnectivity) — requires WatchConnectivity plumbing not yet specified
- CloudKit sync (private database) — requires StreakRecord model, offline queue, conflict resolution
- Siri Shortcuts (AppIntents) — "Log my mood" / "How's my streak?"
- "Your Year in Arc" annual recap — end-of-year summary card
- CoreML on-device mood prediction — predict mood from habit patterns
- Calendar integration — show habits on calendar view
- Additional HealthKit metrics (heart rate, calories, water intake)
- Custom activity tags (beyond preset list) — v1.0 has "+" button for freeform entry, v1.1 adds saved custom tags with autocomplete
- JSON import for non-premium users — currently premium-only (basic JSON export is free per GDPR)
- iPad layout optimization (multi-column, sidebar navigation)
- Habit templates marketplace (community-shared templates)

---

## Privacy Policy Template (Required for App Store Submission)

Host at `https://dailyarc.app/privacy` (or GitHub Pages). Key sections:

**0. Data Controller:** [Your Legal Name / Company Name], [Registered Address], [Country]. Contact: privacy@dailyarc.app. For GDPR inquiries, contact the data controller at the above email.

**1. Data We Collect:** Habits (name, emoji, frequency, completion logs), mood scores (1-5, energy, activities, notes), HealthKit metrics (steps, workouts, sleep, mindful minutes — only when user explicitly enables), email address (optional, only if you choose to sign up for weekly summary emails). We do NOT collect: name, location, contacts, photos, browsing data, or purchase history.

**2. Where Data Is Stored:** All data is stored locally on your device using Apple's SwiftData framework. We do not operate servers. Your data stays on your device, with two exceptions: (a) anonymous analytics sent to TelemetryDeck (see Section 4), and (b) your email address, if voluntarily provided with marketing consent, is shared with Buttondown (our email delivery provider, buttondown.com) under a Data Processing Agreement for the sole purpose of delivering weekly summary emails. You can unsubscribe from any email or delete your email from DailyArc via Settings → Privacy. **Data retention:** Your data is retained on your device for as long as you use the app. There is no automatic expiration or deletion. You may delete all data at any time via Settings → Delete All My Data. Upon app deletion, iOS removes all app data including SwiftData stores and UserDefaults.

**2b. Legal Basis for Processing (GDPR Article 13(1)(c)):**
| Processing Activity | Legal Basis | GDPR Article |
|---------------------|-------------|--------------|
| Core habit/mood tracking | Consent (affirmative opt-in during onboarding) | 6(1)(a) |
| HealthKit data processing | Explicit consent (health data, special category) | 9(2)(a) |
| Anonymous analytics (TelemetryDeck) | Consent (opt-in, default OFF) | 6(1)(a) |
| Age verification | Legal obligation (COPPA compliance) | 6(1)(c) |

**3. HealthKit Data:** We access HealthKit data only when you explicitly enable auto-logging for a specific habit. HealthKit data is read-only (we never write to HealthKit). HealthKit data is never transmitted off-device, never shared with third parties, and never used for advertising. This complies with Apple's HealthKit guidelines.

**4. Analytics:** We use TelemetryDeck for privacy-respecting analytics. TelemetryDeck does not use device identifiers (IDFA), does not track you across apps or websites, and applies differential privacy. We collect anonymous aggregate signals only: app opens, feature usage counts, crash reports. No personal data is included.

**5. Your Rights:**
**GDPR (EU residents):** Right to Access: export all your data via Settings → Export JSON (free). Right to Erasure: delete all data via Settings → Delete All My Data. Right to Portability: JSON export is always free. Right to Restrict Processing: you control all data processing via in-app toggles. Right to Withdraw Consent: Settings → Privacy → Withdraw Consent. **Right to Object (Art. 21):** You have the right to object to processing based on legitimate interests. Since DailyArc processes data solely on the basis of consent (not legitimate interests), this right is satisfied by the ability to withdraw consent at any time. If we introduce any legitimate-interest-based processing in future versions, we will provide a dedicated objection mechanism. Right to Lodge a Complaint: you have the right to lodge a complaint with your local data protection authority if you believe your data has been processed unlawfully (list of EU DPAs: edpb.europa.eu). Contact: privacy@dailyarc.app.

**CCPA (California residents):** We do not sell, rent, or share your personal information with third parties for monetary or other valuable consideration. We share email addresses (if voluntarily provided) with Buttondown, our email delivery service provider, solely for the purpose of delivering weekly summary emails. Buttondown acts as a service provider under the CCPA and does not use your information for its own commercial purposes. Under the CCPA, you have the right to: know what personal information we collect, request deletion of your data, and opt out of the sale of your data. Since we do not sell data, there is nothing to opt out of. To exercise your rights, use the in-app data management tools or contact privacy@dailyarc.app.

**6. Children's Privacy (COPPA):** We require date-of-birth verification. Users under 13 cannot use the app. We do not knowingly collect data from children under 13. **Reinstall protection:** Age gate DOB is stored in Keychain (not just UserDefaults/AppStorage) so it survives app reinstall. On first launch, check Keychain for existing DOB before showing onboarding. If DOB exists and user is still under 13, show block screen immediately without re-prompting. This prevents the bypass-by-reinstall vector.

**7. Mental Health Disclaimer:** DailyArc is a self-tracking tool, not a medical device. It does not diagnose, treat, cure, or prevent any condition. Mood-habit correlations are statistical observations, not clinical advice. If you are experiencing mental health concerns, please consult a licensed healthcare professional.

**8. Data Breach Notification (GDPR Art. 33/34):** In the unlikely event of a data breach affecting personal data (e.g., a vulnerability in the app that could expose on-device data to unauthorized access), we will: (a) notify the relevant supervisory authority within 72 hours of becoming aware of the breach (Art. 33), including the nature of the breach, categories of data affected, approximate number of users affected, likely consequences, and measures taken to mitigate; (b) if the breach is likely to result in a high risk to your rights and freedoms, notify affected users directly via App Store update release notes and an in-app banner on next launch (Art. 34), describing the breach in clear language and recommending protective actions. Since DailyArc stores all data on-device with no server component, the primary breach vector is an app-level vulnerability — mitigation is delivered as a priority app update. Breach notification records are maintained for supervisory authority review.

**9. LGPD Compliance (Brazil):** For users in Brazil, DailyArc complies with the Lei Geral de Proteção de Dados (LGPD). **Legal basis:** Consent (LGPD Art. 7(I)) for habit/mood data processing; explicit consent (LGPD Art. 11(I)) for health-related data (mood-habit correlations). **Children (Art. 14):** Processing of personal data of children under 18 requires parental consent. The DOB age gate enforces this by requiring parental confirmation for users under 18 in Brazil. **Data subject rights (Art. 18):** Right to confirmation, access, correction, anonymization, portability (JSON export), deletion (Delete All My Data), and information about shared entities (none — all data on-device). **International transfer:** Anonymous analytics to TelemetryDeck (EU-based) — permissible under LGPD Art. 33(II) as data is anonymized via differential privacy prior to transfer.

**10. APPI Compliance (Japan):** For users in Japan, DailyArc complies with the Act on the Protection of Personal Information (APPI). **Purpose of use:** Personal data (habits, mood scores, energy scores, HealthKit metrics) is processed solely for the purpose of providing habit tracking, mood logging, and correlation insights to the individual user. **Cross-border disclosure:** Anonymous analytics data is transmitted to TelemetryDeck (EU-based), which constitutes cross-border transfer. TelemetryDeck applies differential privacy and does not process personal data — this transfer is permissible under APPI Art. 28 as the data is anonymized prior to transfer. **APPI-specific rights:** Right to request disclosure of retained personal data, right to request correction or deletion, right to request cessation of use — all exercisable via in-app data management tools (Export JSON, Delete All My Data) or by contacting privacy@dailyarc.app.

**11. TTDSG Compliance (Germany):** For users in Germany, DailyArc complies with the Telekommunikation-Telemedien-Datenschutz-Gesetz (TTDSG). **TTDSG §25 (cookie/storage consent):** DailyArc stores data in on-device SwiftData, UserDefaults, and Keychain. These are technically necessary for the app's functionality and do not require separate TTDSG consent beyond the GDPR consent already collected. TelemetryDeck SDK stores a session hash in memory (not persistent storage) — no TTDSG consent needed. **If we add persistent analytics identifiers in future versions**, TTDSG §25(1) consent will be required before storage.

**12. COPPA Verifiable Parental Consent (for users 13-15 in applicable jurisdictions):** COPPA requires verifiable parental consent for children under 13 (blocked by DailyArc's age gate). For users aged 13-15 in the EU (GDPR Art. 8), member states may set a digital consent age as high as 16. DailyArc does not require account creation and processes data on-device only, which reduces the scope of parental consent obligations. However, to be safe: users who enter a DOB indicating age 13-15 see an additional information screen: "Please make sure a parent or guardian knows you're using this app." This is an informational notice, not a consent gate — blocking 13-15 year olds entirely would be disproportionate for an on-device utility app.

**13. Changes to This Policy:** We will update this page if our practices change. **Date format:** Use ISO 8601 (`YYYY-MM-DD`) for machine readability AND a human-readable localized date (e.g., "March 15, 2026" / "15. März 2026" / "2026年3月15日") for each translated version. Last updated: [launch date].

---

## Terms of Service / EULA (Required for IAP Apps)

Host at `https://dailyarc.app/terms`. Link in Settings + App Store Connect "License Agreement" field. Key sections:

**1. Acceptance:** By downloading or using DailyArc, you agree to these terms.
**2. License:** We grant you a personal, non-transferable license to use the app on devices you own.
**3. In-App Purchase:** Premium unlock is a one-time, non-consumable purchase. Family Sharing enabled per App Store Connect. No refunds through DailyArc — Apple handles refunds per their policy.
**4. User Content:** You own all data you create (habits, mood entries, notes). We do not access, view, or store your content on any server.
**5. Prohibited Use:** Do not reverse engineer, redistribute, or use the app for any unlawful purpose.
**6. Disclaimer:** The app is provided "as is" without warranty of any kind. To the maximum extent permitted by law, our aggregate liability arising from your use of DailyArc shall not exceed the amount you paid for the app ($5.99 or local equivalent). We are not liable for indirect, incidental, or consequential damages including data loss. Nothing in these terms excludes liability that cannot be excluded under applicable law, including liability for death or personal injury caused by negligence, fraud, or any other liability that cannot be limited under mandatory applicable law. DailyArc is not a medical device (see mental health disclaimer).
**7. Termination:** We may update or discontinue the app. Your local data remains on your device regardless.
**8. Governing Law:** [Your jurisdiction]. To the extent not addressed herein, Apple's standard Licensed Application End User License Agreement (LAEULA) applies. Disputes resolved per Apple's standard terms unless superseded here.

---

## Post-Launch Monitoring Plan

**Week 1 Dashboard (check daily):**
| Metric | Source | Alert threshold |
|--------|--------|----------------|
| Crash-free rate | MetricKit / Xcode Organizer | < 99.5% → investigate immediately |
| DAU | TelemetryDeck | < 50% of day-1 installs by day 3 |
| Onboarding completion | TelemetryDeck | < 70% → simplify onboarding |
| Day 1 retention | TelemetryDeck | < 40% → investigate first session UX |
| Day 7 retention | TelemetryDeck | < 20% → investigate habit loop |
| Premium conversion | TelemetryDeck | < 4% → A/B test paywall |
| App Store rating | App Store Connect | < 4.0 → prioritize bug fixes |
| Day 14 retention | TelemetryDeck | < 15% → investigate insight unlock awareness (is Day 14 nudge firing? is Stats tab visited?) |
| Day 30 retention | TelemetryDeck | < 10% → investigate post-insight engagement drop-off |

**Review Response Plan:** Respond to all 1-2 star reviews within 48 hours. Thank positive reviewers. Never argue. For bug reports: "Thank you — we've identified this and a fix is coming in the next update."

**North Star Metric:** Weekly Active Loggers (users who logged ≥1 habit in the past 7 days). This measures sustained engagement, not downloads.

**Analytics Event Taxonomy (TelemetryDeck signals — comprehensive):**
| Event Name | Parameters | Trigger |
|-----------|-----------|---------|
| `app_launched` | `source` (cold/warm/widget/notification) | App becomes active |
| `onboarding_page_viewed` | `page` (1/2/3) | Page appears |
| `onboarding_completed` | `habits_selected` (count), `goal` | "Start Your Arc" tap |
| `habit_logged` | `habit_count`, `is_auto_logged` | Habit reaches targetCount |
| `mood_logged` | `mood_score`, `has_energy`, `has_activities` | Mood emoji tap |
| `streak_milestone` | `milestone` (3/7/14/30/100/365), `habit_id_hash` | Milestone reached |
| `insight_viewed` | `correlation_count`, `is_significant` | Insights segment appears |
| `paywall_viewed` | `trigger` (limit/feature/teaser/onboarding/settings) | Paywall appears |
| `premium_purchased` | `price`, `days_since_install` | Transaction verified |
| `share_card_generated` | `milestone`, `card_type` (streak/insight/weekly) | Share tapped |
| `share_card_shared` | `milestone`, `destination` | Share sheet completed |
| `export_completed` | `format` (json/csv), `object_count` | Export finishes |
| `widget_timeline_requested` | `family` (small/medium/large) | Timeline provider called |
| `error_occurred` | `type`, `context` | Any user-facing error |
| `experiment_assigned` | `experiment`, `variant` | First flag read |
| `habit_created` | `source` (template/custom), `habit_count_after` | New habit saved |
| `habit_archived` | `habit_id_hash`, `days_tracked` | Habit archived |
| `habit_deleted` | `habit_id_hash`, `days_tracked`, `had_streak` | Habit permanently deleted |
| `paywall_dismissed` | `trigger`, `time_on_paywall_ms`, `action` (not_now/back/swipe) | Paywall closed without purchase |
| `notification_opened` | `type` (reminder/activation/milestone/reactivation) | User tapped notification |
| `notification_permission` | `status` (granted/denied/not_determined) | Permission dialog result |
| `streak_lost` | `previous_length`, `habit_id_hash` | Streak broken (gap >1 day) |
| `streak_recovered` | `recovered_length`, `gap_days` | Streak recovery used |
| `healthkit_permission` | `types_granted` (count), `types_denied` (count) | HealthKit dialog result |
| `healthkit_sync_completed` | `records_synced`, `duration_ms` | Background HealthKit sync finishes |
| `onboarding_skipped` | `page` (which page user skipped from) | User taps "Skip" during onboarding |
| `settings_opened` | `section` (if deep-linked) | Settings screen appears |
| `help_article_viewed` | `article_id`, `category` | In-app help article opened |
| `data_exported` | `format` (json/csv), `file_size_kb` | Export file generated |
| `data_deleted` | `scope` (single_habit/all_data) | User deletes data |
| `age_gate_blocked` | `entered_age` | User blocked by COPPA age gate |
| `consent_changed` | `consent_type` (analytics/mood_correlation/healthkit), `new_value` | User toggles consent |
| `thermal_state_change` | `device_model`, `current_screen`, `thermal_state` | ProcessInfo thermal state changes |
| `cold_launch_deferred_ms` | `total_ms`, `slowest_task` | Deferred launch tasks complete |

**Feature Adoption KPIs (track weekly, segment by free/premium):**
| Feature | Target Adoption (Day 30) | Signal to Track | Action if Below Target |
|---------|--------------------------|-----------------|----------------------|
| HealthKit integration | 40% of users grant ≥1 type | `healthkit_permission` with types_granted>0 | Improve permission prompt timing/copy |
| Widget installed | 15% of Day 7+ users | `widget_timeline_requested` unique users | Add widget promotion in Settings, post-milestone |
| Mood logging | 60% of activated users log ≥1 mood/week | `mood_logged` weekly unique | Improve mood UI discoverability, test prompt |
| Insight viewed | 80% of Day 14+ premium users | `insight_viewed` unique users | Check insight card visibility, add nudge |
| Share card used | 5% of milestone earners | `share_card_generated` / `streak_milestone` | Improve share CTA prominence, test copy |
| Notifications enabled | 50% of Day 1 users | `notification_permission` granted | Test permission timing (after first log vs onboarding) |
| JSON export used | 3% of Day 30+ users | `data_exported` unique users | Informational only — low usage is acceptable |

**Revenue Analytics KPIs (track weekly):**
| KPI | Definition | Target | Signal |
|-----|-----------|--------|--------|
| ARPI (Avg Revenue Per Install) | Total revenue / total installs | $0.30+ | App Store Connect |
| Days to conversion | Median days from install to premium purchase | <14 days | `premium_purchased` → `days_since_install` |
| Paywall-to-purchase by surface | Conversion rate per paywall trigger | Varies | `paywall_viewed` trigger → `premium_purchased` within session |
| Paywall view rate | % of Day 3+ users who see paywall | 60%+ | `paywall_viewed` unique / DAU |
| Paywall dismiss rate | % of paywall views closed without action | <80% | `paywall_dismissed` / `paywall_viewed` |
| Restore purchases rate | % of purchases that are restores vs new | <20% | Track restore vs new in `premium_purchased` |

**Conversion Funnel (track in TelemetryDeck):**
Install → Onboarding complete → First habit logged → **Activated** (3-of-7 days + at least 1 mood log in first 7 days) → Day 7 active → Insight teaser viewed → Paywall viewed → Premium purchased

**Activation Metric (primary):** A user is "activated" when they have logged at least 1 habit on 3 of their first 7 days AND logged at least 1 mood entry. This dual requirement ensures users have engaged with both core value propositions (habit tracking + mood correlation). Target activation rate: 60%+. If below 50%, investigate onboarding friction (are templates being selected? is the first tap-to-log too many taps from launch? is mood logging discoverable enough?). Track in TelemetryDeck. This definition is the single source of truth — the conversion funnel (above) uses the same criteria.

**Activation Metric (secondary — habit-only):** Track `user_activated_habit_only` for users who log habits on 5 of their first 7 days WITHOUT logging mood. This captures Persona 3 ("Simple Streaker") who values habit tracking but not mood logging. These users are legitimately engaged but would be misclassified as non-activated by the primary metric. **Do NOT use this secondary metric for conversion funnel segmentation** — the primary metric remains authoritative for premium conversion analysis. The secondary metric is for retention analysis and persona validation only. Fires `user_activated_habit_only` event to TelemetryDeck with same parameters as primary event.

**`user_activated` event timing:** The event fires at the moment the criteria are met (e.g., Day 3 if user logged all 3 days consecutively), NOT at the end of Day 7. This enables real-time notification cadence adjustments (activation recovery notifications reference this).

**Day-0 micro-metric:** Track "time to first value" — seconds from onboarding completion to first habit tap. Target: median < 60 seconds. If median > 120 seconds, the Today View is not surfacing the first action clearly enough. Track in TelemetryDeck: `first_habit_logged` with `seconds_since_onboarding` parameter. Target: 90%+ of users log within 5 minutes of onboarding completion.

**Activation recovery notifications (Days 1-7 cadence — separate from generic reminders):**
- Day 1 (6 hours after onboarding complete, if no habit logged): "Your first day is almost done — tap to check in."
- Day 2 morning (if Day 1 had a log): "Day 2 — keep the momentum going."
- Day 3 (if Days 1-2 had logs): "One more day and you'll start seeing patterns."
- Day 4 (if active on 3 of first 4 days): "Your arc is taking shape — 3 more days to your first weekly trend."
- Day 5 (if 3+ active days): "Halfway to your first week! Your data is already building insights."
- Day 6 (if 3+ active days): "Tomorrow is Day 7 — a badge awaits. One more day."
- These fire only during the activation window (first 7 days) and are separate from the generic evening reminder. Gated by `@AppStorage("activationDay")` counter. **`user_activated` event:** When the user meets the activation criteria (3 of 7 days with habit log + at least 1 mood log), log `user_activated` to TelemetryDeck with `activation_day` (which day of first 7 they qualified) and `habit_count`. This is the single most important growth signal — segment ALL downstream metrics by activated vs non-activated.

**Viral Coefficient (K-factor):** K = (share rate per user) × (conversion rate per share). Target for v1.0: K ≥ 0.05 (realistic for a utility app with no social features). Measure via App Store Connect campaign token attribution from share card `ct` parameters. Decision framework: if K < 0.03 after 1000 users, prioritize referral incentive for v1.0.1. If K > 0.1, invest in additional share surfaces (weekly summary share, insight share cards).

**Retention Cohort Targets (track weekly in TelemetryDeck):**
| Cohort | Target | Action if below |
|--------|--------|-----------------|
| Day 1 | ≥40% | Investigate first-session UX, time-to-first-value |
| Day 7 | ≥20% | Investigate habit loop, notification opt-in rate |
| Day 14 | ≥15% | Investigate insight unlock awareness, Day 12-14 nudge effectiveness. Day 14 is the insight-unlock cliff — users who don't discover insights here rarely convert to premium. Remediation: verify insight nudge banner fires, test copy variants, check notification delivery rate. |
| Day 30 | ≥12% | Analyze streak loss recovery rate, insight engagement |
| Day 90 | ≥8% | Review long-term value delivery, badge progression |
Segment by: free vs premium, activation status, persona (if identifiable from habit count/type). Run monthly cohort comparison to detect regression.

**Premium Conversion Target:** 5-7% of users who reach Day 7 should convert. Alert at <4% (not <3% as previously stated — 3% is too low for a one-time purchase with a 3-habit free limit). If <4%: A/B test paywall copy, test $4.99 vs $5.99 pricing.

### Growth Experiment Framework

**Feature flag infrastructure ships in v1.0** (all experiments default to control — zero behavior change at launch, but the plumbing is in place for v1.0.1 fast-follow without architecture changes):

```swift
enum FeatureFlag: String, CaseIterable {
    case paywallTiming = "experiment_paywall_timing"
    case onboardingTemplates = "experiment_onboarding_templates"
    case shareCardFrequency = "experiment_share_frequency"

    /// Read variant from UserDefaults. @AppStorage is a property wrapper for SwiftUI views —
    /// it cannot be used as a local variable inside a computed property.
    var variant: String {
        UserDefaults.standard.string(forKey: self.rawValue) ?? "control"
    }

    /// Assign variant (used by experiment assignment logic in v1.0.1)
    func setVariant(_ value: String) {
        UserDefaults.standard.set(value, forKey: self.rawValue)
    }

    /// ASSIGNMENT MECHANISM (activate in v1.0.1): Use deterministic hash-based bucketing:
    /// ```swift
    /// import CryptoKit
    /// let data = Data(stableUserID.uuidString.utf8)
    /// let hash = SHA256.hash(data: data)
    /// let bucket = Int(hash.prefix(4).reduce(0) { $0 << 8 | UInt($1) } % 100)
    /// ```
    /// where stableUserID is a UUID generated at first launch and stored in Keychain
    /// (survives app reinstalls). **CRITICAL: Do NOT use `String.hashValue` — it is
    /// randomized per process since Swift 4.2 (SE-0206) and produces different buckets
    /// on every app launch.** SHA256 is deterministic and stable across launches.
    /// Bucket 0-33 = control, 34-66 = variant A, 67-99 = variant B (equal thirds for balanced statistical power).
    /// **Rollout percentages:** New features (non-experiment) use progressive rollout:
    /// 5% → 25% → 50% → 100% over 4 days, monitoring crash-free rate at each stage.
    /// If crash-free rate drops below 99.5% at any stage, halt rollout and investigate.
    /// Experiments use equal splits (33/33/34) from activation for maximum statistical power.
    /// **TTDSG Section 25 compliance (German market):** Do NOT generate stableUserID in Keychain
    /// at first launch unconditionally. Instead, defer generation to the first moment it is actually
    /// needed: (a) user grants analytics consent (TelemetryDeck needs it), or (b) feature flag
    /// activation in v1.0.1, or (c) user taps Share (share card attribution needs it).
    /// Storing a persistent identifier before consent would violate TTDSG Section 25 (German
    /// implementation of ePrivacy Directive Art. 5(3)) which requires consent before storing
    /// information on the user's terminal equipment unless strictly necessary for the service.
    /// Access via `KeychainService.stableUserID` which lazily generates on first access.
    /// This ensures balanced cohorts, deterministic assignment, and reinstall-safe bucketing.
}
```

**A/B Testing Framework:** The FeatureFlag enum (above) is the unified experiment infrastructure for ALL A/B tests across the app — paywall timing, correlation algorithm variants, onboarding flows, and share card frequency. Each experiment: (1) is defined as a `FeatureFlag` case, (2) uses deterministic SHA256 bucketing for consistent assignment, (3) logs assignment to TelemetryDeck, (4) has pre-computed sample size requirements. **Correlation algorithm A/B test (v1.1):** Add `FeatureFlag.correlationThresholds` to test the current 0.15/0.3/0.5 thresholds against alternatives (e.g., 0.1/0.25/0.4 for more sensitive detection). Metric: insight engagement rate (tap-to-expand on correlation cards). Requires n ≈ 800 per variant at 80% power.

**Four planned A/B tests (activate in v1.0.1 via TelemetryDeck remote config or simple server JSON):**

1. **Paywall timing:** Control = paywall shown when user hits 3-habit limit. Variant A = paywall shown after Day 3 (engagement-based trigger, subtle bottom banner not blocking sheet). Variant B = paywall shown after first insight viewed (full paywall sheet). **Paywall copy variants (within each timing variant):** Control copy = "Unlock Your Full Arc" (current). Variant A copy = "See What Makes You Happier" (insight-led). Variant B copy = "Track Every Habit" (utility-led). Test copy independently from timing in a 3×3 matrix once N supports it. Metric: premium conversion rate at Day 30.
2. **Onboarding template count:** Control = 1–3 habits. Variant = 3 pre-selected (user deselects). Metric: Day 7 retention rate.
3. **Share card frequency:** Control = milestones only (7/30/100/365). Variant = add weekly summary share card option. Metric: share rate per WAL.
4. **Price point:** Control = $5.99. Variant A = $4.99. Variant B = $7.99. Uses App Store product configuration (no code change). Metric: revenue per user at Day 30 (not just conversion rate — lower price may convert more but earn less).

**Implementation:** Each experiment logs a `TelemetryDeck.signal("experiment_\(name)_\(variant)")` on assignment.

**Sample size requirements (pre-computed using G*Power-equivalent calculations):**
| Experiment | Metric | Baseline | MDE (minimum detectable effect) | Power | Required N per variant |
|-----------|--------|----------|------|-------|----------------------|
| Paywall timing | Conversion rate | 5% | 50% relative lift (2.5pp) | 80% | ~620 | **Feasible** (6-12 weeks at 100/week) |
| Onboarding templates | Day 7 retention | 25% | 20% relative lift (5pp) | 80% | ~1,100 | **Feasible** (11-22 weeks) |
| Share card frequency | Share rate per WAL | 3% | 50% relative lift (1.5pp) | 80% | ~2,700 | **Likely infeasible** — reduce to 2 variants (N=2,700→1,800 total) or widen MDE to 75% lift (N~1,200/variant) |
| Price point | Revenue/user at D30 | $0.30 | 20% relative lift ($0.06) | 80% | ~1,500 | **Slow** (15-30 weeks) — prioritize last |
**Feasibility note (indie launch reality):** At projected install velocity of 50-200/week, Experiments 1-2 are feasible within v1.0.x cycle. Experiment 3 should be simplified to 2 variants (control vs weekly summary) to halve required N. Experiment 4 (price) should be deferred until cumulative installs exceed 3,000. If velocity is <50/week after Week 4, defer ALL experiments and focus on organic growth.
**Decision rule:** Do NOT declare a winner until the pre-computed N is reached, even if early results look promising (multiple-testing inflation). Use sequential analysis (O'Brien-Fleming spending function) only if install velocity supports it.

**Paid Acquisition Channel Strategy (activate post-launch, budget-dependent):**
- **Apple Search Ads (primary, Week 2+):** See ASO section for detailed strategy. $50-100/month initial budget. Highest-intent channel — users are actively searching.
- **Reddit Ads (secondary, Week 4+):** Target r/habits, r/DecidingToBeBetter, r/getdisciplined. Promoted post format matching organic content ("I built a privacy-first habit tracker"). $30-50/month. Track via campaign-tagged App Store link.
- **Pre-registration landing page (Week -6, free):** Set up `dailyarc.app/launch` with Buttondown email capture form: "Be first to know when DailyArc launches." Campaign tag: `ct=prelaunch_email`. Target: 100-300 email signups before launch day. These become Day 1 install cohort. All pre-launch social content (Reddit dev journey posts, Twitter threads, Show HN) links here. Convert pre-launch interest into measurable demand before the App Store listing goes live.
- **Paid acquisition contingency (Week 4 decision gate):** If ALL paid channels exceed $3.00 CPA threshold after 100 conversions each, go fully organic. Cap total paid spend at $300 before the 90-day revenue review. Do not chase unprofitable paid channels — the app's strength is organic discovery through privacy positioning and word-of-mouth.
- **Product Hunt launch (one-time, Launch Day):** Free, high-impact. Prepare: maker video, first comment explaining "why I built this", 5+ upvotes from beta testers at launch hour.
- **Organic only (free):** Reddit posts (value-first, not promotional), Twitter/X dev log, Hacker News "Show HN" post.
- **Channels to avoid (v1.0):** Facebook/Instagram ads (high CPA for utility apps), TikTok (poor fit for non-visual product), influencer sponsorships (budget-prohibitive for indie).
- **LTV/CPA framework:** One-time purchase = $5.99 LTV cap. Maximum sustainable CPA: $3.00 (50% margin). Pause any channel exceeding $3.00 CPA after 100 conversions.

**Re-engagement campaign for churned users (v1.0.1):**
- **In-app:** Lapsed user re-engagement cards already specified (14-30 days, 30-60 days, 60+ days absent).
- **Push notification:** Reactivation reminders at 3/5/7/10/14 days (already specified, stops after Day 14).
- **Email (if opted in):** Day 30 absent: "Your arc is waiting" with personal stats summary (longest streak, total habits logged). Day 60: "A lot can change in 60 days. Your data is safe." Final email, then stop.
- **No paid retargeting** — on-device-only architecture means we have no server-side user list for ad targeting. This is a feature (privacy), not a bug.

**Activation timeline:**
- **v1.0 (launch):** All flags default to control. No experiments active. Ship infrastructure only.
- **v1.0.1 (Week 2-3 post-launch, ~500+ installs):** Activate Experiment 1 (paywall timing) first — highest revenue impact. Activation via hosted JSON at `dailyarc.app/flags.json` (static file, no server needed). App fetches on launch, caches in UserDefaults. **Phased rollout:** Submit to App Store with phased release enabled (7-day automatic rollout: 1%→2%→5%→10%→20%→50%→100%). Monitor crash-free rate and 1-star reviews at each phase. Pause rollout if crash-free rate drops below 99% or 3+ 1-star reviews mention the same issue.
- **v1.0.2 (Week 6-8, ~1500+ installs):** Activate Experiments 2-3 (onboarding templates, share frequency) once Experiment 1 reaches N=500/variant. Phased rollout (same 7-day cadence).
- **v1.0.3 (Week 10-12):** Activate Experiment 4 (price point) via App Store Connect product configuration — requires separate SKU setup. Full rollout (price changes apply globally via App Store Connect, not phased).
- **Decision criteria:** Declare winner when **p < 0.05 two-tailed** (not one-tailed — two-tailed is standard for A/B tests where the variant could perform worse) AND practical significance threshold met (>10% relative lift for conversion, >5% for retention). **No-significance decision rule:** If no significance at 1.5× the pre-computed N per variant, declare no meaningful difference, remove the experiment flag, and ship the simplest variant (lowest code complexity). Do NOT extend experiments indefinitely hoping for significance — this inflates false positive rates.
- **Minimum sample:** Gate A/B activation on **cumulative install count ≥3,000** (not calendar weeks). Track install velocity in first 2 weeks. If <50 installs/week, defer experiments to avoid underpowered tests.
- **Experiment interaction controls:** Experiments 1 (paywall timing) and 4 (price point) are **mutually exclusive** — a user cannot be in both simultaneously, as price sensitivity confounds paywall timing results. Implementation: if assigned to Exp 1, skip Exp 4 assignment (and vice versa). Experiments 2 and 3 are independent and may overlap. **Per-experiment SHA256 salting:** Each experiment uses a distinct salt in the SHA256 bucketing: `SHA256(stableUserID + experiment.rawValue)`. This ensures independent randomization across experiments — users in Exp 1 control are not systematically in Exp 2 control.

**Experiment hypotheses (required — every experiment must state its hypothesis before activation):**
| Experiment | Null Hypothesis (H₀) | Alternative Hypothesis (H₁) |
|-----------|----------------------|-------------------------------|
| 1. Paywall timing | Engagement-based paywall timing does not affect Day 30 conversion rate vs limit-based timing | Engagement-based timing increases Day 30 conversion by ≥2.5pp |
| 2. Onboarding templates | Pre-selected templates do not affect Day 7 retention vs user-selected | Pre-selected templates increase Day 7 retention by ≥5pp |
| 3. Share card frequency | Weekly summary share option does not affect share rate per WAL | Weekly share option increases share rate by ≥1.5pp |
| 4. Price point | $4.99 or $7.99 does not change Day 30 revenue per user vs $5.99 | At least one alternative price changes revenue/user by ≥20% |

**Experiment guardrail metrics (monitor for ALL experiments — halt if any degrades):**
| Guardrail | Threshold | Action if Breached |
|-----------|-----------|-------------------|
| Day 7 retention (variant) | Must not drop >3pp below control | Halt experiment, investigate |
| App Store rating (rolling 7-day) | Must not drop below 4.0 | Halt experiment, investigate |
| Crash-free rate | Must not drop below 99% | Halt experiment immediately |
| Support email volume | Must not increase >2× baseline | Review experiment UX for confusion |

### Variable Reward Hooks (v1.0 — Nir Eyal's Hook Model)

**Trigger → Action → Variable Reward → Investment** loop built into the daily flow:
1. **Trigger:** Morning notification ("How are you feeling?") + evening reminder ("Quick check-in keeps momentum going")
2. **Action:** One-tap habit logging + emoji mood tap (lowest possible friction)
3. **Variable Reward:** Randomized celebration messages at milestones (not same toast every time), rotating journaling prompts (deterministic by day but novel to user), weekly summary with new stat each week (this week's top activity, mood average comparison to last week)
4. **Investment:** Each day logged increases the value of insights ("14 more days to unlock correlations"), streak length creates switching cost, badge collection creates completionism motivation

### Measurable Share Links (v1.0)

Share cards include a **campaign-tagged App Store link** for attribution:
- Format: `https://apps.apple.com/app/dailyarc/id{APPID}?pt={PROVIDER_TOKEN}&ct=share_streak_{milestone}`
- The `ct` (campaign token) parameter allows tracking which milestone generated the most installs in App Store Connect → Analytics → Sources
- Track in TelemetryDeck: `share_card_generated` (with milestone as parameter), `share_card_shared` (user completed share sheet)
- This provides measurable viral coefficient data from Day 1 without requiring a backend

### Lightweight Referral Surface (v1.0)

**Deferred deep link strategy for v1.1 referral attribution:** Apple does not pass `ct` campaign tokens to the app at runtime — they are only visible in App Store Connect analytics. For v1.1 in-app referral badge detection, implement a deferred deep link via `dailyarc.app/ref/{stableUserID}` redirect (Universal Link) that stores the referrer ID in a URL parameter. On first launch, check if the app was opened via a Universal Link and extract the referrer. This requires no backend — the redirect can be a static Cloudflare Pages rule. Alternative: use `SKAdNetwork` for coarse attribution if Universal Links prove unreliable.

**v1.0 ships a minimal referral surface** (not the full badge-based system, which is v1.1):
- **Surface:** "Share DailyArc" button in two locations: (1) Settings → About section, (2) inside badge ceremony modals for 30+ day milestones (alongside the existing "Share" button for the streak card).
- **Action:** Tapping opens a `ShareLink` with a pre-formatted message: "I've been tracking my habits with DailyArc and it's helped me see what actually affects my mood. Check it out: {App Store link with campaign token `ct=referral_organic`}."
- **No badge reward in v1.0** — the share is purely organic/altruistic. Badge rewards come in v1.1.
- **Tracking:** Log `referral_share_tapped` and `referral_share_completed` (share sheet dismissed with activity selected) to TelemetryDeck. This provides baseline referral rate data for v1.1 optimization.

### Referral Incentive (v1.1)

Post-launch: "Give premium, get premium" — user shares a referral link. When the referred user upgrades, both get a thank-you badge ("🤝 Arc Sharer" for referrer, "🌟 Referred Arc" for new user). No monetary incentive (avoids IAP complications). Track via App Store attribution or custom deep link with user UUID.

**Referral mechanics (v1.1 spec):**
- **Share surface:** "Invite a Friend" row in Settings + share prompt after 30-day milestone celebration.
- **Link format:** `https://dailyarc.app/ref/{stableUserID_short}` → redirect to App Store with `ct=referral_{id}`.
- **Attribution:** On first launch, check if `ct` parameter starts with `referral_`. If so, store referrer ID in `@AppStorage("referredBy")`. When new user upgrades, log `referral_converted` to TelemetryDeck with both user IDs.
- **Badge award:** Referrer receives badge on their next app launch (check via `dailyarc.app/referrals/{id}.json` — static file updated by a simple webhook from App Store Server Notifications).
- **UGC strategy (v1.1):** Enable "My Arc Story" share template — a pre-formatted share card with the user's top insight, longest streak, and a personal quote (user-editable, max 100 chars). Shareable to Instagram Stories (1080×1920) and Twitter. Encourage with a toast after 100-day milestone: "Your arc tells a story. Want to share it?"
- **UGC testimonial collection (v1.0):** After 30 days of active use (≥20 of 30 days with at least one habit logged), show a one-time in-app prompt: "Loving DailyArc? We'd love to hear your story." with two options: (1) "Share feedback" → opens a simple text field (max 280 chars) + optional permission toggle: "DailyArc may feature my words (anonymized) in marketing." Stored locally in `@AppStorage("userTestimonial")` and `@AppStorage("testimonialPermission")`. (2) "Not now" → dismisses permanently. Track via `@AppStorage("testimonialPromptShown")`. **No server upload in v1.0** — testimonials are collected on-device and manually harvested during TestFlight/beta feedback sessions. This provides authentic social proof for App Store screenshots and marketing without requiring backend infrastructure.

**v1.0 referral data collection (prep for v1.1):** At first launch, generate a `stableUserID` (UUID, stored in Keychain — already needed for feature flag bucketing). When users share cards, embed this ID in the campaign URL `ct` parameter. This provides attribution data in App Store Connect without requiring a backend. At v1.1, this ID enables the referral badge system. **No PII is collected** — the UUID is random, not linked to any personal data, and only appears in App Store Connect analytics.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| App Store rejection (HealthKit paywall) | Low | High | HealthKit is always free — verified in spec and tests |
| Crash-free rate <99% at launch | Medium | High | MetricKit monitoring, TestFlight beta with 5+ testers, XCUITest smoke tests |
| Day 7 retention <15% | Medium | High | Motivation valley mitigation (Days 3-14), notification re-engagement, weekly summary |
| Premium conversion <3% | Medium | Medium | A/B test paywall timing, price point experiments, Day 14 insight teaser |
| SwiftData corruption on disk | Low | Critical | ModelContainer failure recovery (repair/reset), Keychain DOB survives reset |
| HealthKit observer callback data loss | Medium | Medium | `beginBackgroundTask` wrapping, post-save dedup, 3-layer defense in depth |
| GDPR complaint (mood = health data) | Low | High | DPIA completed, Art. 9 explicit consent, granular withdrawal, on-device-only |
| Timezone change breaks streaks | Low | Medium | Calendar-based normalization, DST handling, accepted IDL limitation |
| Notification fatigue → uninstall | Medium | Medium | Daily budget of 3, priority queue, compassionate tone, easy disable |
| Memory pressure on older devices (365-day heat map) | Medium | Medium | Per-screen budgets, memory pressure handler, progressive loading |
| Feature flag drift (stale experiments) | Low | Medium | Flag cleanup lifecycle (below), quarterly audit |

**Social Media Crisis Communication Protocol:**
| Tier | Trigger | Response Time | Action |
|------|---------|--------------|--------|
| Monitor | Single negative post, <10 engagements | Track only | Log in monitoring doc, do not engage |
| Respond | Negative post from 5K+ follower account, or gaining traction (>50 engagements) | <4 hours | Reply publicly: acknowledge concern, provide factual correction if needed, offer to continue in DM. Template: "Thanks for raising this. [Factual response]. Happy to discuss further — DM us anytime." |
| Escalate | Viral criticism (>100 engagements), health/safety allegations, or press inquiry | <1 hour | Reply with holding statement: "We take this seriously and are looking into it. We'll share a full response shortly." Then prepare detailed thread/post within 24 hours. |

**Pre-drafted responses:**
- **Privacy concern:** "DailyArc's habit and mood data never leaves your device. We have no servers and no access to your data. Our architecture is detailed in our privacy policy: [link]. Happy to answer specific questions."
- **Mental health concern:** "DailyArc is a self-tracking tool, not a medical device. We include disclaimers throughout the app and encourage anyone with mental health concerns to consult a professional. We take this responsibility seriously."
- **Pricing complaint:** "We chose a one-time $5.99 purchase because we believe you shouldn't rent your own habits. No subscriptions, no ads, no data selling. We think that's fair."

**Risk register ownership:** Each risk has an implicit owner — the developer (solo project). Review risk register monthly during the first 3 months post-launch, then quarterly. Update likelihood/impact based on actual data (e.g., if crash-free rate is 99.8%, downgrade that risk).

**Feature flag cleanup lifecycle:** When an experiment concludes: (1) merge winning variant into code as the new default, (2) remove the `FeatureFlag` case and all branching code, (3) remove the flag from `flags.json`, (4) remove stale `@AppStorage` experiment assignments via a one-time migration (check for orphaned keys on app update). Target: no flag lives longer than 90 days. Stale flags create hidden complexity and make the codebase harder to reason about.

---

## Technical Debt & Known Limitations

1. **Streak is local-only.** No CloudKit sync for streaks. Users on multiple devices have independent streaks. Acceptable for v1; add StreakRecord model in v1.1 if demand warrants.

2. **No offline queue.** Not needed for v1 (everything is local). Required when CloudKit is added in v1.1.

3. **Widget data is eventually consistent.** Main app writes debounced JSON to UserDefaults; widgets read it on timeline refresh. Brief staleness (up to ~1 second + timeline reload) is acceptable.

4. **HealthKit backfill limited to 30 days.** Prevents excessive data import on first sync. Users who want historical data can use manual logging.

5. **Free tier limits are enforced client-side.** A jailbroken device could bypass them. Acceptable risk for a $5.99 IAP — not worth server-side enforcement complexity.

6. **HabitLog.fetchOrCreate uses fetchLimit=1 with a compound predicate** (date + habit.id). The predicate filters by both normalized date AND habit ID, so at most one result is returned. If a timezone change creates two logs for the "same" day, the first found wins. CloudKit sync in v1.1 will need a proper conflict resolution strategy. Note: `#Predicate { $0.habit?.id == habitID }` requires the `habitID` local variable to be a captured `let` — SwiftData #Predicate closures cannot traverse optional keypaths without a captured intermediate value.

7. **CorrelationEngine thresholds are tuned for binary/ordinal data** (behavioral science norms: 0.15/0.3/0.5). These may need adjustment once real user data is available. Consider A/B testing threshold values in v1.1.

8. **No #Unique constraint on HabitLog (habit + date).** Avoided because #Unique interacts poorly with CloudKit sync. The fetchOrCreate upsert pattern handles uniqueness in code, but a race condition is theoretically possible under extreme concurrency. @ModelActor serialization mitigates this for HealthKit callbacks.

9. **Pipe delimiter for activities/customDays is a pragmatic choice.** To prevent parsing breakage, **strip pipe characters from user-entered custom activity tags** at input time: `tag.replacingOccurrences(of: "|", with: "")`. Also enforce a max tag length of 30 characters and trim whitespace. This is cheaper than migrating to JSON-encoded strings for v1.0. v1.1 should migrate to a proper array type or JSON-encoded string for robustness.

10. **isRecovered flag on HabitLog is boolean.** Does not capture recovery reason or original miss date. Acceptable for v1 insights exclusion; v1.1 could add richer recovery metadata.

---

## Data Lifecycle & Store Health

**Data retention and compaction strategy (v1.0):**
- **Full-resolution retention window:** 365 days. All HabitLog and MoodEntry records within the last 365 days are kept at full resolution (individual entries per habit per day).
- **Historical compaction (beyond 365 days):** Records older than 365 days are compacted into a `DailyArcSchemaV1.DailySummary` model: one row per date storing aggregated completion counts per habit, mood average, and energy average. This reduces 5-habit × 365-day data from ~1,825 rows to ~365 rows per year.
- **DailySummary model (add to SchemaV1 in v1.0 to avoid migration):**
```swift
@Model class DailySummary {
    var date: Date           // normalized start-of-day
    var habitCompletionsJSON: String  // JSON-encoded [String: Int] — habitID UUID string to count
    var moodAverage: Double  // 0 = no mood logged that day
    var energyAverage: Double
    var createdAt: Date

    /// Type-safe accessor — decodes JSON to dictionary
    var habitCompletions: [String: Int] {
        get { (try? JSONDecoder().decode([String: Int].self, from: Data(habitCompletionsJSON.utf8))) ?? [:] }
        set { habitCompletionsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "{}" }
    }
}
// #Index<DailySummary>([\.date])
// NOTE: date should be unique (one summary per day) but #Unique avoided for CloudKit compat.
// DataCompactionService must check for existing DailySummary before inserting (idempotency).
// Add DailySummary.self to DailyArcSchemaV1.models array.
```
- **DataCompactionService:** Runs weekly via `BGAppRefreshTask`. Processes records older than 365 days: aggregates into DailySummary rows, then deletes the original HabitLog/MoodEntry records. Budget: <5 seconds (background task). Log `data_compaction` with `records_compacted` count. **Transactional safety:** Process one date at a time within a single `ModelContext.save()` (insert DailySummary + delete source records atomically per date). Process oldest-first so partial completion is safe. **Idempotency:** Before aggregating a date, check if a `DailySummary` already exists for that date — skip if so. This prevents double-counting if the background task is interrupted and restarted.
- **CorrelationEngine and RuleEngine:** Operate on the most recent 365 days of full-resolution data only. Heat map uses DailySummary for years beyond the current one (color from completionCount, no drill-down detail).

**SwiftData store health monitoring (v1.0):**
- On each launch (deferred task), measure `ModelContext.fetchCount()` for HabitLog and Habit. Log `store_health` to TelemetryDeck with `habit_count`, `log_count`, `store_size_mb` (file size of `.store` file in application support directory).
- **VACUUM strategy:** SwiftData/SQLite does not auto-reclaim space after deletions. After "Delete All My Data" or bulk habit deletion (≥5 habits), trigger a manual VACUUM by closing and reopening the ModelContainer. Log `store_vacuum` with `before_mb` and `after_mb`. Do NOT VACUUM on every launch — it rewrites the entire database file and is O(N) in database size.
- **3-year regression test:** Include a unit test that creates a simulated 3-year dataset (1,095 days × 5 habits = 5,475 HabitLogs + 1,095 MoodEntries) and verifies: (a) store size <50MB, (b) CorrelationEngine completes in <2s, (c) heat map renders in <200ms, (d) fetchOrCreate remains <5ms. Run on CI with every merge.
- **Store corruption detection:** On ModelContainer init failure (catch in DailyArcApp.swift), attempt recovery: (1) try opening with `isStoredInMemoryOnly: true` to verify schema, (2) if schema is valid, the store file is corrupt — prompt user to export (if possible) then reset, (3) if schema migration fails, log `store_migration_failure` and present recovery UI. Never silently delete user data.
- **Automatic backup verification (Rule 39):** After each BGAppRefreshTask backup to iCloud Drive container, verify the backup by reading the first 1KB and checking for valid JSON/SQLite header. Log `backup_verified` or `backup_corrupt` to TelemetryDeck.

---

## Revenue Expansion Path

**v1.0 revenue model:** One-time $5.99 IAP. LTV cap = $5.99. No recurring revenue.

**Revenue expansion evaluation criteria (for v1.1+ consideration):**
| Model | Evaluate When | Minimum Threshold | Implementation Complexity |
|-------|--------------|-------------------|--------------------------|
| Annual subscription ($14.99/yr) | Premium conversion >7% AND Day 90 retention >10% | Projected ARR >$10K | High — requires subscription management, trial periods, grace periods |
| Theme/icon packs ($1.99 each) | DAU >2K AND user requests for customization | >500 premium users requesting themes | Low — cosmetic, no feature gating |
| "Year in Arc" premium recap ($2.99) | Users reach 365-day milestones | >100 users with 365+ days data | Medium — one-time seasonal feature |
| Family sharing unlock ($9.99) | Family sharing requests in support | >50 family sharing inquiries | Low — StoreKit 2 family sharing built-in |

**90-day revenue model review (MANDATORY):** At Day 90 post-launch, conduct a formal revenue model evaluation. If cumulative revenue is below $500 (~83 premium conversions), mandate evaluating the subscription model using the criteria table above. If Day 30 retention >15% AND premium conversion >5% by Week 8, fast-track subscription model development rather than waiting for the full threshold matrix. Document the decision and rationale.

**Revenue guardrails (never violate):**
- HealthKit features remain free forever (App Store policy + brand promise)
- GDPR data export remains free forever (legal requirement)
- No ads, ever (brand value: calm, not attention-extracting)
- No data selling, ever (privacy architecture is the product)
- One-time purchase users never lose features they paid for (grandfathering rule if subscription introduced)

---

## Appendix A: Instagram Marketing Strategy

> **NOTE (v28 reconciliation):** The channel analysis (Growth Experiment Framework) explicitly recommends avoiding Instagram for v1.0 due to high CPA for utility apps. This appendix is retained as a **Month 3+ stretch channel** — activate ONLY after Reddit and Twitter/X are producing measurable results (>50 attributed installs each). Do NOT invest Instagram time during Months 1-2. **Kill threshold:** If Instagram drives <50 attributed installs in 60 days of active posting, sunset the channel.

**Goal:** Build visual brand presence and drive organic installs through aspirational habit-tracking content. **v1.0 reduced cadence (solo dev bandwidth):**

**Content pillars (3-pillar rotation):**
1. **Product showcase** (40%): Clean screenshots, feature highlights, before/after data visualizations
2. **Habit inspiration** (40%): Quotes, habit stacking tips, "What I Tracked This Week" templates
3. **Behind the build** (20%): Indie dev journey, design decisions, user stories (with permission)

**Posting cadence (reduced for solo dev — activate Month 3+):**
| Format | Frequency | Best Time (EST) | Content Type |
|--------|-----------|-----------------|-------------|
| Feed posts | 1×/week | Sat 8am | Repurposed from blog/Twitter content |
| Stories | Skip for v1.0 | — | Too time-intensive for solo dev; revisit at Month 6 |
| Reels | 1×/week | Fri 12pm | 15-30s: app walkthroughs, repurposed from Twitter video |

**Instagram-specific tactics:**
- **Bio link:** Linktree or similar with: App Store link (campaign-tagged `ct=instagram_bio`), privacy policy, support email
- **Story highlights:** Organize into: "Features", "Tips", "Reviews", "FAQ", "Behind the Build"
- **Branded hashtag:** `#MyDailyArc` — encourage users to share their stats/share cards. Repost (with permission) to Stories weekly
- **UGC strategy:** After each repost, DM the user a thank-you + ask for App Store review. Target: 5 UGC posts/month by Month 6
- **Collaboration:** Engage with #habittracking, #selfimprovement, #wellnessjourney communities. Comment genuinely (no spam)

**KPIs (adjusted for reduced cadence):**
| Metric | Month 3 Target | Month 6 Target |
|--------|----------------|----------------|
| Followers | 200 | 1,000 |
| Engagement rate | 5%+ | 4%+ |
| Profile visits → link clicks | 10%+ | 8%+ |
| Attributed installs (ct=instagram_*) | 25 | 100 |

---

## Appendix A2: Twitter/X Strategy

**Goal:** Build indie dev credibility, share the building-in-public journey, and drive organic installs through authentic engagement. Twitter/X is the primary social channel alongside Reddit from Day 1.

**Content pillars (4-pillar rotation):**
1. **Dev log threads** (30%): "Building DailyArc" numbered series — weekly threads sharing SwiftUI/SwiftData learnings, design decisions, progress updates. Authentic, educational, builds following before launch.
2. **Habit science** (25%): Short threads distilling research (Fogg, Gollwitzer, Lally) into practical insights. Establishes domain authority. Link back to blog when available.
3. **Product updates** (25%): Feature reveals, screenshot previews, milestone announcements (TestFlight, launch, 1K installs). Use video/GIF for UI demos.
4. **Engagement** (20%): Reply to habit/wellness conversations, quote-tweet interesting takes, ask questions ("What's the one habit that changed your life?"). Community-first, never self-promotional in replies.

**Posting cadence:**
| Format | Frequency | Best Time (EST) | Content Type |
|--------|-----------|-----------------|-------------|
| Tweet/thread | 5×/week | 8-9am Mon-Fri | Dev log (Mon), habit science (Tue/Thu), product (Wed), engagement (Fri) |
| Quote-tweet/reply | Daily | Throughout day | React to relevant conversations in habit/wellness/indie dev space |
| Video/GIF demo | 1×/week | Wed 12pm | 15-30s app walkthrough, feature demo, or UI animation showcase |

**Thread templates:**
1. **Dev log:** "Building DailyArc #N: [topic]. Here's what I learned about [SwiftData/Canvas/HealthKit] this week 🧵" → 4-6 tweets with code snippets or screenshots → final tweet: "Following along? [link to TestFlight or App Store]"
2. **Habit science:** "TIL: [surprising research finding about habits]. Here's why it matters for building a habit tracker 🧵" → 3-4 tweets → "This is why DailyArc does [feature]"
3. **Launch day:** "I just shipped DailyArc — a habit + mood tracker that runs 100% on your device. Here's the 14-week journey 🧵" → 8-10 tweets covering motivation, key decisions, what I'd do differently → App Store link

**Engagement tactics:**
- Follow and engage with: indie dev accounts, habit/productivity creators, SwiftUI community, Apple developer advocates
- Use hashtags: `#MyDailyArc` (branded), `#BuildInPublic`, `#IndieApp`, `#SwiftUI`, `#iOSDev`
- Reply to every mention and DM within 24 hours during first 3 months
- Pin launch thread to profile

**KPIs:**
| Metric | Month 1 Target | Month 3 Target | Month 6 Target | Action Threshold |
|--------|---------------|----------------|----------------|-----------------|
| Followers | 300 | 1,000 | 2,500 | <100 at Month 1 → increase thread frequency |
| Avg impressions/thread | 1,500 | 5,000 | 10,000 | <500 → rewrite hooks, add visuals |
| Engagement rate | 3%+ | 2.5%+ | 2%+ | <1.5% → increase engagement tweets, reduce promotional |
| Link clicks (ct=twitter_*) | 50 | 200 | 500 | <20 at Month 1 → improve CTAs |
| Thread completion rate | 40%+ | 40%+ | 35%+ | <25% → shorten threads to 4 tweets max |

---

## Appendix B: Reddit Community Strategy

**Goal:** Build authentic community presence in habit/wellness subreddits before and after launch.

**6-week pre-launch plan:**
| Week | Action | Subreddit | Post Type |
|------|--------|-----------|-----------|
| -6 to -4 | Establish presence: comment helpfully on habit-tracking posts | r/habits, r/DecidingToBeBetter | Helpful comments (no self-promotion) |
| -3 | Share indie dev journey post | r/iOSProgramming, r/SwiftUI | "Building a habit tracker — lessons learned" |
| -2 | Share design decisions post | r/userexperience, r/Design | "Why I chose on-device-only architecture" |
| -1 | Teaser/beta invite post | r/habits, r/getdisciplined | "Looking for beta testers for a privacy-first habit tracker" |
| Launch | Launch post | r/Apple, r/iphone, r/habits, r/ClaudeAI | Value-first: "I built X because Y wasn't available" |
| +1 | Follow-up engagement | All above | Reply to every comment, share learnings |

**Subreddit matrix (prioritized by relevance and rule strictness):**
| Subreddit | Size | Self-promo Rules | Approach |
|-----------|------|-----------------|----------|
| r/habits | 200K+ | Moderate — value-first posts allowed | Primary: share insights, mention app naturally |
| r/DecidingToBeBetter | 500K+ | Strict — no self-promo | Comment-only. Build karma. Never post app links |
| r/getdisciplined | 400K+ | Moderate | Advice posts with app as supporting example |
| r/iOSProgramming | 100K+ | Dev-friendly | Technical deep dives welcome |
| r/SwiftUI | 50K+ | Dev-friendly | Code snippets, SwiftData learnings |
| r/Apple | 4M+ | Strict moderation | Only for major milestones (launch, awards) |

**Story bank (pre-write 5+ genuine stories for Reddit posts):**
1. "Why I built a habit tracker that doesn't sync to the cloud"
2. "What I learned tracking my habits for 100 days (with data)"
3. "The correlation between exercise and mood — my personal data"
4. "Why $5.99 once instead of $5/month — an indie dev's math"
5. "SwiftData in production: what worked and what didn't"

**Influencer and community seeding strategy (pre-launch):**
- Identify 10-20 micro-influencers across three categories: (a) indie iOS dev accounts (5K-50K followers on Twitter), (b) habit/productivity creators (YouTube, Instagram), (c) privacy-focused tech reviewers. Compile in a simple spreadsheet: name, platform, follower count, relevance score.
- **Outreach template:** "Hi [name], I'm building DailyArc — a habit + mood tracker that runs 100% on-device (no cloud, no accounts). I'd love for you to try the TestFlight beta and share honest feedback. No obligation to post — just looking for genuine input. [TestFlight link]"
- Send 10 outreach messages during TestFlight beta (Weeks 14-16). Target: 3-5 acceptances, 1-2 organic mentions.
- After launch: send follow-up with App Store link and a personal thank-you to anyone who provided feedback.

**AMA plan (Month 2 post-launch):** Host on r/iOSProgramming — "I'm a solo dev who shipped a SwiftUI + SwiftData app, AMA about the journey."

**Reddit KPIs:**
| Metric | Target |
|--------|--------|
| Karma earned from habit subreddits | 500+ pre-launch |
| Launch post upvotes | 50+ |
| App Store installs from Reddit (ct=reddit_*) | 200+ in first month |
| Community reputation | Zero removed posts, zero bans |

---

## Appendix C: CloudKit Readiness Assessment

**Status:** CloudKit sync is deferred to v1.1 but requires forward-compatible decisions in v1.0.

**Forward decisions (implement in v1.0 to avoid v1.1 rework):**
| Decision | v1.0 Implementation | Why It Matters for CloudKit |
|----------|---------------------|---------------------------|
| UUID-based identifiers | All models use `UUID` as primary identifier, not `persistentModelID` | CloudKit requires stable, portable identifiers |
| No `#Unique` constraints | Use fetchOrCreate pattern instead | `#Unique` conflicts with CloudKit's merge resolution |
| Sendable model properties | All properties are value types (String, Int, Date, UUID) | CloudKit sync requires Sendable data transfer |
| Flat relationship structure | HabitLog stores `habitIDDenormalized` alongside relationship | CloudKit handles flat records better than deep relationships |
| Deterministic date normalization | `calendar.startOfDay(for:)` everywhere | Cross-device date consistency |
| Export DTO layer | JSON export uses DTO structs, not model objects | DTOs become CloudKit record mappers in v1.1 |

**v1.1 rework table (estimated effort if NOT prepared in v1.0):**
| Item | Rework Without Prep | Rework With Prep |
|------|---------------------|------------------|
| Model migration to CloudKit-compatible schema | 40h | 8h |
| Conflict resolution (last-writer-wins vs merge) | 24h | 16h (still needs design) |
| Offline queue implementation | 20h | 20h (no prep possible) |
| StreakRecord cloud model | 16h | 8h |
| Migration for existing users | 12h | 4h |
| **Total** | **112h** | **56h** |

**Architecture requirements for v1.1 CloudKit:**
- CKContainer with private database (no public/shared — all data is personal)
- `CKRecord` ↔ DTO bidirectional mapping (extend existing export DTOs)
- `CKSubscription` for remote change notifications
- `CKServerChangeToken` stored in UserDefaults for incremental sync
- Conflict resolution: last-writer-wins for HabitLog (idempotent), custom merge for Habit (preserve both edits if non-conflicting fields)
- Offline queue: `NSPersistentCloudKitContainer` handles this if migrating from SwiftData, OR custom queue with retry logic if staying with SwiftData

---

## Appendix D: visionOS & macOS Compatibility Roadmap

**Platform timeline:**
| Platform | Target Version | Priority | Prerequisite |
|----------|---------------|----------|-------------|
| macOS (Designed for iPad) | v1.0 | Free — automatic with SwiftUI | Verify: no UIKit-only APIs, no haptic-only interactions |
| macOS (native Catalyst) | v1.2 | Low | Menu bar support, keyboard shortcuts, window management |
| visionOS | v2.0 | Low | Volumetric UI research, spatial interaction patterns |

**v1.0 macOS compatibility (Designed for iPad — zero additional work):**
- Verify the app runs via "Designed for iPad" on macOS Sonoma+
- Known issues to test: haptics (no-op on Mac — verify graceful degradation), HealthKit (unavailable on macOS — verify permission flow handles absence), widget sizing (verify Mac widget gallery), Keychain access group (verify shared between iOS and macOS versions)
- **Do NOT ship macOS as a separate target in v1.0** — "Designed for iPad" is sufficient for launch

**UIKit abstraction requirements (for future platform expansion):**
- All haptic calls go through `HapticService` (already specified) — swap implementation per platform
- All HealthKit calls go through `HabitLogWriteActor` — make optional with `#if canImport(HealthKit)`
- All notification scheduling through `NotificationService` — adapt for macOS notification center
- No hard-coded screen dimensions — use GeometryReader and relative sizing everywhere
- **All accessibility checks use `AccessibilityEnvironment` helper (rule 39b), NOT UIKit statics**
- **All `UIApplication.shared` calls wrapped behind `BackgroundTaskService` protocol with `#if canImport(UIKit)`**

**visionOS forward-compatibility decisions (implement in v1.0 to reduce future rework):**
| Decision | v1.0 Implementation | Why It Matters for visionOS |
|----------|---------------------|---------------------------|
| SwiftUI-native accessibility | `@Environment(\.accessibilityReduceMotion)` not UIKit statics (rule 39b) | UIAccessibility absent on visionOS |
| No hard UIKit lifecycle deps | `UIApplication.shared` behind protocols (rule 40) | visionOS uses different app lifecycle |
| Relative sizing everywhere | GeometryReader + relative sizing (already specified) | Volumetric windows have arbitrary dimensions |
| Navigation abstraction | TabView with extracted content views | visionOS may use ornaments or spatial navigation |
| Canvas rendering isolation | Heat map Canvas in isolated view | Can be swapped for RealityKit volumetric view |
| Platform-agnostic analytics | `ProcessInfo` not `UIDevice` (rule 39b) | UIDevice absent on visionOS |

**Estimated rework:** Without v1.0 prep: ~80h. With v1.0 prep (rules 39b, 40): ~30h.

---

## Appendix E: AI Integration Roadmap

**Principles:** All AI features MUST be on-device only (Core ML). No cloud AI APIs. User habit and mood data never leaves the device.

**v1.1 features (Core ML, on-device):**
| Feature | Model | Input | Output | Privacy |
|---------|-------|-------|--------|---------|
| Mood prediction | Tabular classifier (CreateML) | Last 7 days: habits completed, day of week, activities | Predicted mood (1-5) + confidence | On-device only, no training data export |
| Smart notification timing | Tabular regressor (CreateML) | Historical: notification → app_open latency by hour | Optimal reminder hour per user | On-device only |
| Habit suggestion | Text classifier (NLModel) | User's existing habits + onboarding goal | 3 suggested habits from template library | On-device only, no user data in model |

**v2.0 features (speculative):**
- Natural language habit logging: "I went for a run" → auto-log "Exercise" habit
- Mood journaling analysis: sentiment scoring on optional free-text entries
- Anomaly detection: flag unusual mood patterns (with mental health disclaimer)

**AI guardrails (apply to all versions):**
- No mood predictions displayed without user explicitly enabling the feature
- Always show confidence interval alongside predictions
- Never frame predictions as medical advice
- User can disable all AI features independently
- No training data exported or shared — models train on-device using user's own data only
- Mental health disclaimer shown on first use of any AI feature

---

## Appendix F: Automated Monitoring & Alerting

**TelemetryDeck dashboard configuration (set up during Step 8):**

**Dashboard 1: Health (check daily for first 2 weeks, then weekly)**
| Panel | Signal | Alert Threshold |
|-------|--------|----------------|
| Crash-free rate | MetricKit crash diagnostics | <99% → investigate immediately |
| Cold launch time (p95) | `cold_launch_deferred_ms` | >2.0s → profile with Instruments (aligned with 2.0s budget) |
| Store health | `store_health` → store_size_mb | >100MB → investigate data accumulation |
| Keychain failures | `keychain_error` | >1% of Keychain operations |
| Widget write latency | `widget_write_slow` | >5% of widget writes >50ms |

**Dashboard 2: Growth (check weekly)**
| Panel | Signal | Alert Threshold |
|-------|--------|----------------|
| WAL (Weekly Active Loggers) | `habit_logged` unique users, 7-day rolling | Week-over-week decline >10% |
| Activation rate | `user_activated` / installs | <50% → investigate onboarding |
| Day 7 retention | Cohort analysis | <20% → investigate motivation valley |
| Premium conversion | `premium_purchased` / Day 7+ users | <4% → A/B test paywall |
| Share rate | `share_card_shared` / WAL | <2% → improve share CTA |

**Dashboard 3: Revenue (check weekly)**
| Panel | Signal | Alert Threshold |
|-------|--------|----------------|
| Weekly revenue | App Store Connect | Below pessimistic scenario ($15/wk) |
| Conversion by paywall trigger | `paywall_viewed` → `premium_purchased` | Any trigger <2% conversion |
| Restore vs new purchases | `premium_purchased` source | Restore rate >30% (may indicate piracy/abuse) |

**Escalation tiers:**
| Tier | Trigger | Response Time | Action |
|------|---------|--------------|--------|
| P0 | Crash-free <99%, data loss reports | Same day | Hotfix, pause phased rollout |
| P1 | Revenue metric drops >50% WoW | 48 hours | Investigate StoreKit, paywall rendering |
| P2 | Retention drops >20% WoW | 1 week | Analyze cohort, check notification delivery |
| P3 | Engagement metric declines | Next release | Investigate, plan fix |

---

## Appendix G: TelemetryDeck Cost Model

**TelemetryDeck pricing (as of 2024):** Free tier = 100K signals/month. Paid starts at $8/month for 500K signals.

**Signal volume projections:**
| Scenario | DAU | Signals/user/day | Monthly signals | Tier | Monthly Cost |
|----------|-----|-----------------|----------------|------|-------------|
| Launch (Month 1) | 50 | 8-12 | ~15K | Free | $0 |
| Base (Month 3) | 300 | 8-12 | ~90K | Free | $0 |
| Growth (Month 6) | 1,000 | 8-12 | ~300K | Paid | $8/mo |
| Optimistic (Month 12) | 3,000 | 8-12 | ~900K | Paid | $8-15/mo |

**Signals per user per session (estimated breakdown):**
- `app_launched`: 1
- `habit_logged`: 2-3 (average habits per session)
- `mood_logged`: 0-1
- Health/performance signals: 1-2 (thermal, launch timing)
- Navigation signals: 2-3 (settings, stats, insights)
- **Total: ~8-12 signals per active session**

**Cost optimization if approaching limits:**
1. Batch health/performance signals: combine `thermal_state_change`, `cold_launch_deferred_ms`, `store_health` into a single `app_diagnostics` signal with parameters
2. Sample non-critical signals at 50% (e.g., `settings_opened`, `help_article_viewed`)
3. Reduce `widget_timeline_requested` to once per day instead of every timeline refresh

---

## Appendix H: Global Analytics Properties

**Properties attached to every TelemetryDeck signal (for segmentation):**

```swift
// Set once at app launch in TelemetryDeck configuration
TelemetryDeck.initialize(config: TelemetryManagerConfiguration(
    appID: "YOUR_APP_ID",
    defaultSignalPrefix: "dailyarc.",
    defaultParameters: [
        "app_version": Bundle.main.appVersion,       // e.g., "1.0.0"
        "build_number": Bundle.main.buildNumber,      // e.g., "42"
        "ios_version": ProcessInfo.processInfo.operatingSystemVersionString, // e.g., "17.4" — cross-platform (visionOS/macOS compatible)
        "device_model": {  // Cross-platform (POSIX, works on iOS/macOS/visionOS)
            var systemInfo = utsname()
            uname(&systemInfo)
            return withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(validatingCString: $0) ?? "unknown" }
            }
        }(),  // e.g., "iPhone15,2"
        "is_premium": String(PremiumManager.shared.isPremium), // "true"/"false"
        "locale": Locale.current.identifier,           // e.g., "en_US"
        "preferred_language": Locale.preferredLanguages.first ?? "unknown",
        "color_scheme": colorScheme == .dark ? "dark" : "light",
        "accessibility_voiceover": accessibilityVoiceOverEnabled ? "true" : "false", // capture from @Environment(\.accessibilityEnabled) in view layer
        "accessibility_reduce_motion": accessibilityReduceMotionEnabled ? "true" : "false", // capture from @Environment(\.accessibilityReduceMotion) in view layer
        "dynamic_type_size": dynamicTypeCategory(),    // "default", "large", "accessibility"
        "experiment_paywall": FeatureFlag.paywallTiming.variant,
        "experiment_onboarding": FeatureFlag.onboardingTemplates.variant,
    ]
))
```

**Segmentation dimensions available on every signal:**
- **Monetization:** is_premium (enables free vs premium behavior comparison)
- **Platform:** device_model, ios_version (identifies device-specific issues)
- **Accessibility:** voiceover, reduce_motion, dynamic_type (ensures inclusive design)
- **Experimentation:** experiment variants (enables experiment analysis without separate events)
- **Localization:** locale, preferred_language (informs localization priority)

**Privacy note:** None of these properties constitute PII. Device model and iOS version are non-identifying in aggregate. No IDFA, no email, no name. TelemetryDeck applies differential privacy on their end.
