import type { Metadata } from "next";
import React from "react";
import { LegalPage, LegalSection } from "../components/LegalPage";
import { GITHUB_ISSUES_URL, MADE_BY_URL } from "../../utils/main.util";

export const metadata: Metadata = {
  title: "Terms & Conditions — HabitMe",
  description:
    "The terms for using HabitMe: a free, local-first habit tracker. Covers your licence, ads, reminder accuracy, backups, warranties and liability.",
};

const sections: LegalSection[] = [
  {
    id: "acceptance",
    title: "Acceptance Of These Terms",
    body: (
      <p>
        By installing, opening or using HabitMe, you agree to these Terms &amp;
        Conditions. If you do not agree, please do not use the app and uninstall
        it. These Terms apply to the Android app, its APK releases, and this
        website.
      </p>
    ),
  },
  {
    id: "service",
    title: "What HabitMe Is",
    body: (
      <>
        <p>
          HabitMe is a free habit tracker for Android. It helps you create
          recurring and one-time habits, group them with labels, see them in a
          list or calendar, receive local reminders, and export or import your
          data.
        </p>
        <p>
          The app works without an account. Your data is stored locally on your
          device; there is no cloud sync and no HabitMe server holding your
          habits. The app is supported by ads, as described below.
        </p>
      </>
    ),
  },
  {
    id: "license",
    title: "Your Licence To Use HabitMe",
    body: (
      <>
        <p>
          You are granted a personal, non-exclusive, non-transferable and
          revocable licence to install and use HabitMe on devices you own or
          control, for your own personal, non-commercial use.
        </p>
        <p>You agree not to:</p>
        <ul>
          <li>Copy, resell, rent, sublicense or redistribute the app as your own product.</li>
          <li>Reverse engineer or modify the app except where the law expressly permits it.</li>
          <li>Remove or alter branding, notices or attribution in the app.</li>
          <li>Use the app in a way that breaks applicable law or the rights of others.</li>
        </ul>
      </>
    ),
  },
  {
    id: "ads",
    title: "Ads And Third-Party Services",
    body: (
      <>
        <p>
          HabitMe is free and displays ads supplied by <strong>Unity Ads</strong>{" "}
          (Unity Technologies). Your use of the app is also subject to Unity’s
          applicable terms and privacy policy. The app needs internet access to
          load ads; the tracker itself works without a connection.
        </p>
        <p>
          We do not control which specific ads are shown and we are not
          responsible for the products, services or claims in third-party
          advertisements. Any transaction you enter into with an advertiser is
          solely between you and that advertiser.
        </p>
      </>
    ),
  },
  {
    id: "reminders",
    title: "Reminders, Timing And Accuracy",
    body: (
      <>
        <p>
          Reminders are scheduled through your device’s operating system. They
          are a convenience, not a guarantee. Delivery can be delayed or blocked
          by battery optimisation, Doze mode, revoked notification or exact-alarm
          permissions, device restarts, manufacturer restrictions, or the system
          limit on pending alarms.
        </p>
        <p>
          HabitMe schedules a rolling batch of your nearest upcoming reminders
          (up to 60 at a time) and refreshes the queue when you open the app, so
          open it regularly if you rely on reminders. Do not use HabitMe for
          critical, safety-related, medical, legal or financial deadlines where a
          missed alert could cause harm or loss. Always keep an independent
          reminder for anything important.
        </p>
      </>
    ),
  },
  {
    id: "your-content",
    title: "Your Content And Backups",
    body: (
      <>
        <p>
          You own the habit names, labels and history you enter. Because they
          live only on your device, <strong>you are responsible for your data</strong>{" "}
          — including keeping backups.
        </p>
        <p>
          The app can export a plain SQL file and import one. Backups are under
          your control once exported; we cannot restore, recover or access them.
          If you uninstall the app or clear its storage, local data is deleted,
          and without a backup it cannot be recovered.
        </p>
      </>
    ),
  },
  {
    id: "not-advice",
    title: "Not Professional Advice",
    body: (
      <p>
        HabitMe is a productivity and self-tracking tool. Nothing in the app or
        on this website is medical, psychological, nutritional, fitness, legal or
        financial advice. Habits you track — including health-related ones — are
        your own choices. Consult a qualified professional before making changes
        that affect your health, medication, finances or legal rights.
      </p>
    ),
  },
  {
    id: "acceptable-use",
    title: "Acceptable Use",
    body: (
      <p>
        Use HabitMe only for lawful, personal purposes. Do not attempt to
        interfere with the app’s security or normal operation, distribute
        modified builds as official HabitMe releases, or use the app or its
        branding to mislead others into thinking you are affiliated with the
        project.
      </p>
    ),
  },
  {
    id: "ip",
    title: "Intellectual Property",
    body: (
      <p>
        The HabitMe name, logo, interface and original code are owned by ItsMe
        Prince. The source code is published on GitHub for transparency; its use
        is governed by the terms and licence information stated in that
        repository. Third-party components, fonts and the Unity Ads SDK remain
        the property of their respective owners.
      </p>
    ),
  },
  {
    id: "updates",
    title: "Updates, Availability And Changes",
    body: (
      <p>
        HabitMe is offered as-is and may change over time. Features may be added,
        altered or removed, and releases may be paused or discontinued. We do not
        guarantee that any particular version or feature will remain available.
        Newer versions may be required for correct operation, and some releases
        may include changes to these Terms.
      </p>
    ),
  },
  {
    id: "warranty",
    title: "Disclaimer Of Warranties",
    body: (
      <p>
        To the fullest extent permitted by law, HabitMe is provided{" "}
        <strong>“as is” and “as available”</strong>, without warranties of any
        kind, express or implied, including merchantability, fitness for a
        particular purpose, accuracy and non-infringement. We do not warrant that
        the app will be error-free, uninterrupted, compatible with every device,
        or that reminders will always fire on time.
      </p>
    ),
  },
  {
    id: "liability",
    title: "Limitation Of Liability",
    body: (
      <p>
        To the fullest extent permitted by law, ItsMe Prince will not be liable
        for indirect, incidental, special, consequential or punitive damages, or
        for lost data, missed reminders, lost opportunities, lost profits, or
        harm arising from reliance on the app, even if advised of the
        possibility. Where liability cannot be excluded, it is limited to the
        amount you paid for the app, which is zero. Nothing here limits rights
        that applicable consumer law does not allow to be limited.
      </p>
    ),
  },
  {
    id: "termination",
    title: "Termination",
    body: (
      <p>
        This licence ends if you breach these Terms. You may end it at any time
        by uninstalling the app. Sections that by their nature should survive
        termination — including ownership, disclaimers, limitation of liability
        and governing law — will continue to apply.
      </p>
    ),
  },
  {
    id: "law",
    title: "Governing Law",
    body: (
      <p>
        These Terms are governed by the laws applicable in the developer’s place
        of operation, without regard to conflict-of-law rules. Disputes will be
        subject to the courts with jurisdiction there, unless mandatory consumer
        protection law in your country gives you the right to bring a claim
        locally.
      </p>
    ),
  },
  {
    id: "terms-changes",
    title: "Changes To These Terms",
    body: (
      <p>
        These Terms may be updated as the app evolves. The revised version will
        be posted on this page with a new “last updated” date. Continuing to use
        HabitMe after an update means you accept the revised Terms.
      </p>
    ),
  },
  {
    id: "contact",
    title: "Contact",
    body: (
      <p>
        Questions about these Terms? Reach out at{" "}
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
    ),
  },
];

export default function TermsPage() {
  return (
    <LegalPage
      active="terms"
      eyebrow="Legal · Terms"
      title="Terms & Conditions"
      intro="The ground rules for using HabitMe — what you can expect from the app, what it expects from you, and the limits that come with a free, local-first tracker."
      updated="25 November 2026"
      sections={sections}
    />
  );
}
