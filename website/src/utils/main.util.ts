/**
 * Every link used on the website lives here.
 *
 * Import from this file instead of hard-coding a URL in a component:
 *
 *   import { GITHUB_RELEASE_URL } from "../../utils/main.util";
 *
 * Relative paths only (no "@/..." alias) so the import works from any depth.
 */

/* -------------------------------------------------------------------------- */
/* External links                                                             */
/* -------------------------------------------------------------------------- */

/** Developer site, linked from the header, footer, about card and drawer mock. */
export const MADE_BY_URL = "https://www.itsmeprince.com";

/** Source repository (Hero "Source Code" button). */
export const GITHUB_REPO_URL = "https://github.com/itsmeprinceyt/habitme";

/** APK releases page, used by every download button. */
export const GITHUB_RELEASE_URL =
  "https://github.com/itsmeprinceyt/habitme/releases";

/** Issue tracker, used as the legal pages' contact channel. */
export const GITHUB_ISSUES_URL = "https://github.com/itsmeprinceyt/habitme/issues";

/** Unity Ads privacy policy, referenced from the Privacy Policy. */
export const UNITY_PRIVACY_POLICY_URL = "https://unity.com/legal/privacy-policy";

/** Unity game player / app user privacy policy, referenced from the policy. */
export const UNITY_GAME_PLAYER_PRIVACY_POLICY_URL =
  "https://unity.com/legal/game-player-and-app-user-privacy-policy";

/* -------------------------------------------------------------------------- */
/* Internal routes                                                            */
/* -------------------------------------------------------------------------- */

/** Cross-page hrefs. Landing-page sections are scrolled to via refs, not hashes. */
export const ROUTES = {
  home: "/",
  privacy: "/privacy",
  terms: "/terms",
} as const;

export type Route = (typeof ROUTES)[keyof typeof ROUTES];
