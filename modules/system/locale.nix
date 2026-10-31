{ lib, ... }:

{
  time.timeZone = "Europe/Warsaw";

  # Язык — русский, форматы (даты, числа, валюта, бумага) — польские.
  i18n = {
    defaultLocale = "ru_RU.UTF-8";
    extraLocaleSettings = lib.genAttrs [
      "LC_ADDRESS"
      "LC_IDENTIFICATION"
      "LC_MEASUREMENT"
      "LC_MONETARY"
      "LC_NAME"
      "LC_NUMERIC"
      "LC_PAPER"
      "LC_TELEPHONE"
      "LC_TIME"
    ] (_: "pl_PL.UTF-8");
  };
}
