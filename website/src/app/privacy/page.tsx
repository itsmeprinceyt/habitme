import type { Metadata } from "next";
import React from "react";
import { LegalPage, LegalSection } from "../components/LegalPage";
import {
  GITHUB_ISSUES_URL,
  MADE_BY_URL,
  UNITY_GAME_PLAYER_PRIVACY_POLICY_URL,
  UNITY_PRIVACY_POLICY_URL,
} from "../../utils/main.util";

export const metadata: Metadata = {
  title: "Privacy Policy — HabitMe",
  description:
    "How HabitMe handles your data: no account, no cloud sync, habits stored only on your device, local notifications, local SQL backups, and ads served by Unity Ads.",
};

const sections: LegalSection[] = [
  {
    id: "short-version",
    title: "The Short Version",
    body: (
      <>
        <p>
          HabitMe has <strong>no account, no sign-in and no cloud sync</strong>.
          Your habits, labels and completion history are stored in a local
          database on your own phone. We do not have a server that receives
          them, and we cannot read them.
        </p>
        <p>
          HabitMe is free and supported by ads delivered through{" "}
          <strong>Unity Ads</strong>. That ad SDK is the only third-party
          service in the app, it needs internet access to fetch ads, and it may
          process limited device and advertising data as described below. It
          never receives your habit content from us.
        </p>
        <p>
          Backups are files that you export and choose where to send. We never
          receive a copy.
        </p>
      </>
    ),
  },
  {
    id: "scope",
    title: "What This Policy Covers",
    body: (
      <>
        <p>
          This policy applies to the HabitMe Android application (package name{" "}
          <strong>com.itsmeprince.habitme</strong>), the APK releases published
          on GitHub, and this website. HabitMe is made by ItsMe Prince.
        </p>
        <p>
          It does not cover third-party services you choose to open or share to
          (for example GitHub, your file manager, or the app you use to receive
          a shared backup). Those services have their own policies.
        </p>
      </>
    ),
  },
  {
    id: "on-device-data",
    title: "What HabitMe Stores On Your Device",
    body: (
      <>
        <p>
          Everything you enter lives in a private SQLite database (
          <strong>habitme.db</strong>) inside the app’s own storage:
        </p>
        <ul>
          <li>Habit names, schedule type (recurring or one-time), intervals, due dates and enabling of reminders.</li>
          <li>Labels (names and colours) you create to group habits.</li>
          <li>A completion log of when each habit was marked done.</li>
          <li>Small UI preferences, such as which sections you left expanded.</li>
        </ul>
        <p>
          This data stays on your device. It is not uploaded, synced, analysed
          or backed up to us, and other apps cannot read the app’s private
          storage under normal Android behaviour.
        </p>
      </>
    ),
  },
  {
    id: "not-collected",
    title: "What We Do Not Collect",
    body: (
      <>
        <p>We do not collect or ask for:</p>
        <ul>
          <li>Your name, email address, phone number or any account details.</li>
          <li>Your location, contacts, photos, files or microphone/camera access.</li>
          <li>Health records or data from health platforms — habit names and history never leave the device.</li>
          <li>Analytics, usage events, crash reports or advertising profiles of our own.</li>
        </ul>
        <p>
          The app contains no analytics or crash-reporting SDK. We do not
          operate a backend that stores user data, so there is no copy of your
          habits for us to sell, share or lose.
        </p>
      </>
    ),
  },
  {
    id: "ads",
    title: "Advertising And Third-Party SDKs",
    body: (
      <>
        <p>
          HabitMe is free, and ads are how it stays free. Ads are delivered by{" "}
          <strong>Unity Ads</strong>, a service of Unity Technologies. To fetch
          and display ads, the app declares the Android{" "}
          <strong>INTERNET</strong> permission; this is the only reason the app
          uses a network connection.
        </p>
        <p>
          When an ad is requested or shown, the Unity Ads SDK may process:
        </p>
        <ul>
          <li>A resettable advertising identifier and general device identifiers.</li>
          <li>Device and app information such as model, operating system version, language and app version.</li>
          <li>IP address, and an approximate region derived from it.</li>
          <li>Ad events such as impressions, clicks, skips and completions.</li>
        </ul>
        <p>
          This information is processed by Unity under its own policies, not
          stored by us. We do not receive your habit data with ad requests, and
          we do not build profiles of you. Unity’s policies are available at{" "}
          <a
            href={UNITY_PRIVACY_POLICY_URL}
            target="_blank"
            rel="noopener noreferrer"
          >
            unity.com/legal/privacy-policy
          </a>{" "}
          and{" "}
          <a
            href={UNITY_GAME_PLAYER_PRIVACY_POLICY_URL}
            target="_blank"
            rel="noopener noreferrer"
          >
            unity.com/legal/game-player-and-app-user-privacy-policy
          </a>
          .
        </p>
        <p>
          <strong>Your controls:</strong> on Android you can reset or delete your
          advertising ID and opt out of personalised ads in Settings → Google →
          Ads (paths vary by device). Where the law requires it, ads are served
          on a non-personalised basis. Blocking all network access to the app
          will stop ads, and the habit tracker itself keeps working normally.
        </p>
      </>
    ),
  },
  {
    id: "notifications",
    title: "Notifications And Device Permissions",
    body: (
      <>
        <p>
          Reminders are scheduled locally by your operating system. Habit
          content in a reminder is never sent anywhere. To do this, HabitMe may
          request:
        </p>
        <ul>
          <li>
            <strong>Notifications</strong> — to show habit reminders.
          </li>
          <li>
            <strong>Exact alarms</strong> (Android 12+) — so a reminder arrives
            at the time you chose instead of being delayed by battery
            optimisation.
          </li>
          <li>
            <strong>Wake lock and vibrate</strong> — to display and alert you
            even when the screen is off.
          </li>
          <li>
            <strong>Boot completed</strong> — to restore your scheduled
            reminders after a restart or app update.
          </li>
        </ul>
        <p>
          You can change or revoke any of these at any time in Android settings.
          Revoking them does not affect your saved habits; reminders simply stop
          or may arrive late.
        </p>
      </>
    ),
  },
  {
    id: "backups",
    title: "Backups, Export And Import",
    body: (
      <>
        <p>
          HabitMe can export your database as a plain <strong>.sql</strong> file.
          The file is created on your device and handed to the Android share
          sheet or file picker, so you decide where it goes — local storage, a
          cloud drive, or another app.
        </p>
        <p>
          We never receive that file. Importing a backup reads a file you choose
          and merges it into your local database. Because backups contain your
          habit history, treat them like any other personal file: store them
          somewhere you trust and delete old copies you no longer need.
        </p>
      </>
    ),
  },
  {
    id: "retention",
    title: "Retention And Deleting Your Data",
    body: (
      <>
        <p>
          Your habit data remains on your device until you remove it. You can
          delete individual habits in the app, or remove everything at once by
          clearing the app’s storage in Android settings or uninstalling
          HabitMe. Uninstalling also removes the local database and app
          preferences.
        </p>
        <p>
          Exported backup files are outside the app’s storage. If you shared or
          saved one, you will need to delete it from wherever you put it.
          Advertising data processed by Unity is retained according to Unity’s
          own policy.
        </p>
      </>
    ),
  },
  {
    id: "children",
    title: "Children’s Privacy",
    body: (
      <p>
        HabitMe is not directed at children under 13 (or the minimum age required
        in your country). We do not knowingly collect personal information from
        children — we do not collect personal information from anyone. If a
        child uses the app, habit data stays on that device and can be removed by
        clearing app storage or uninstalling it.
      </p>
    ),
  },
  {
    id: "security",
    title: "Security",
    body: (
      <>
        <p>
          Keeping data on-device removes the risk of a server breach affecting
          your habits. The database sits in the app’s private storage, and habit
          content is not transmitted for ads or notifications.
        </p>
        <p>
          No method of storage is perfectly secure. Anyone with physical access
          to an unlocked device, or with device-level backup/root access, may be
          able to read the app’s files. Please use your device lock and keep your
          own backups safe.
        </p>
      </>
    ),
  },
  {
    id: "rights",
    title: "Your Choices And Rights",
    body: (
      <>
        <p>
          Privacy laws such as the GDPR and CCPA give you rights to access,
          correct, export or delete personal data held about you. Because we do
          not hold your personal data, there is nothing on our side to request,
          correct or delete:
        </p>
        <ul>
          <li>Your habits and history are viewable and deletable inside the app.</li>
          <li>You can export a full copy yourself at any time from the app.</li>
          <li>
            For data processed by the ad SDK, use the advertising controls on
            your device and Unity’s privacy resources linked above.
          </li>
        </ul>
      </>
    ),
  },
  {
    id: "links",
    title: "Third-Party Links",
    body: (
      <p>
        The app and this website link to external sites such as GitHub and
        itsmeprince.com. We are not responsible for the content or privacy
        practices of those sites; please review their policies before sharing
        information with them.
      </p>
    ),
  },
  {
    id: "changes",
    title: "Changes To This Policy",
    body: (
      <p>
        If HabitMe’s data behaviour changes — for example a new service or a new
        permission — this page will be updated and the date above revised.
        Significant changes will also be mentioned in the release notes for the
        affected version. Continuing to use the app after an update means you
        accept the revised policy.
      </p>
    ),
  },
  {
    id: "contact",
    title: "Contact",
    body: (
      <>
        <p>
          Questions about this policy or how HabitMe handles data? Reach out at{" "}
          <a
            href={MADE_BY_URL}
            target="_blank"
            rel="noopener noreferrer"
          >
            itsmeprince.com
          </a>{" "}
          or open an issue on the{" "}
          <a
            href={GITHUB_ISSUES_URL}
            target="_blank"
            rel="noopener noreferrer"
          >
            HabitMe GitHub repository
          </a>
          .
        </p>
      </>
    ),
  },
];

export default function PrivacyPolicyPage() {
  return (
    <LegalPage
      active="privacy"
      eyebrow="Legal · Privacy"
      title="Privacy Policy"
      intro="HabitMe is built to keep your routines on your device. This page explains exactly what the app stores, what it never collects, and the one third-party service it uses to show ads."
      updated="25 November 2026"
      sections={sections}
    />
  );
}
