import { requireOptionalNativeModule } from "expo";
import { Platform } from "react-native";

export const composerAzooKeyAvailable =
  Platform.OS === "ios" &&
  requireOptionalNativeModule<{ azooKeyAvailable?: boolean }>("T3ComposerEditor")
    ?.azooKeyAvailable === true;
