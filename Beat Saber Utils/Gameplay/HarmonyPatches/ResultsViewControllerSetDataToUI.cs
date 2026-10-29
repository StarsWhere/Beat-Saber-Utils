using System.Text;
using HarmonyLib;
using HMUI;
using TMPro;
using UnityEngine;

namespace BS_Utils.Gameplay.HarmonyPatches
{
    [HarmonyPatch(typeof(ResultsViewController), nameof(ResultsViewController.SetDataToUI))]
    internal class ResultsViewControllerSetDataToUI
    {
        private static void Postfix(ResultsViewController __instance)
        {
            __instance._rankText.overflowMode = TextOverflowModes.Overflow;
            __instance._rankText.richText = true;

            GameObject bannerGo = __instance._clearedBannerGo.activeInHierarchy ? __instance._clearedBannerGo : __instance._failedBannerGo;

            GameObject bgGo = bannerGo.transform.Find("BG").gameObject;
            CurvedTextMeshPro tmp = bannerGo.GetComponentInChildren<CurvedTextMeshPro>();
            if (bannerGo == __instance._failedBannerGo)
                tmp.color = Color.red;
            if (bgGo != null)
                bgGo.SetActive(true);
            if (ScoreSubmission.WasDisabled || ScoreSubmission.prolongedDisable)
            {
                string color = "<color=#ff0000ff>";
                StringBuilder scoreSubmissionTextBuilder = new StringBuilder("  \r\n").Append(color).Append("<size=50%><b>Score Submission Disabled by: ");
                if (ScoreSubmission.WasDisabled)
                {
                    scoreSubmissionTextBuilder.Append(ScoreSubmission.LastDisabledModString);

                    if (ScoreSubmission.prolongedDisable)
                        scoreSubmissionTextBuilder.Append(" | ");
                }

                if (ScoreSubmission.prolongedDisable)
                {
                    scoreSubmissionTextBuilder.Append(ScoreSubmission.ProlongedModString);
                }

                tmp.color = Color.white;
                tmp.text += scoreSubmissionTextBuilder.ToString();
                tmp.enableWordWrapping = false;
                if(bgGo != null)
                    bgGo.SetActive(false);
            }

            ScoreSubmission.ModList.Clear();
            ScoreSubmission.disabled = false;
        }
    }
}
