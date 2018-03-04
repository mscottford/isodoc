require "yaml"

module IsoDoc
  class Convert

    def i18n_init(lang, script)
      @lang = lang
      @script = script

      if @i18nyaml
        y = YAML.load_file(@i18nyaml)
      elsif lang == "en"
        y = YAML.load_file(File.join(File.dirname(__FILE__), "i18n-en.yaml"))
      elsif lang == "fr"
        y = YAML.load_file(File.join(File.dirname(__FILE__), "i18n-fr.yaml"))
      elsif lang == "zh" && script == "Hans"
        y = YAML.load_file(File.join(File.dirname(__FILE__), "i18n-zh-Hans.yaml"))
      else 
        y = YAML.load_file(File.join(File.dirname(__FILE__), "i18n-en.yaml"))
      end
      @term_def_boilerplate = y["term_def_boilerplate"]
      @scope_lbl = y["scope"]
      @symbols_lbl = y["symbols"]
      @introduction_lbl = y["introduction"]
      @foreword_lbl = y["foreword"]
      @termsdef_lbl = y["termsdef"]
      @termsdefsymbols_lbl = y["termsdefsymbols"]
      @normref_lbl = y["normref"]
      @bibiliography_lbl = y["bibliography"]
      @clause_lbl = y["clause"]
      @annex_lbl = y["annex"]
      @no_terms_boilerplate = y["no_terms_boilerplate"]
      @internal_terms_boilerplate = y["internal_terms_boilerplate"]
      @norm_with_refs_pref = y["norm_with_refs_pref"]
      @norm_empty_pref = y["norm_empty_pref"]
      @external_terms_boilerplate = y["external_terms_boilerplate"]
      @internal_external_terms_boilerplate =
        y["internal_external_terms_boilerplate"]
      @note_lbl = y["note"]
      @note_xref_lbl = y["note_xref"]
      @termnote_lbl = y["termnote"]
      @figure_lbl = y["figure"]
      @formula_lbl = y["formula"]
      @table_lbl = y["table"]
      @key_lbl = y["key"]
      @example_lbl = y["example"]
      @example_xref_lbl = y["example_xref"]
      @where_lbl = y["where"]
      @wholeoftext_lbl = y["wholeoftext"]
      @draft_lbl = y["draft"]
      @inform_annex_lbl = y["inform_annex"]
      @norm_annex_lbl = y["norm_annex"]
      @modified_lbl = y["modified"]
      @deprecated_lbl = y["deprecated"]
      @source_lbl = y["source"]
      @and_lbl = y["and"]
      @all_parts_lbl = y["all_parts"]
      @locality = y["locality"]
    end

    def eref_localities1(type, from, to, lang = "en")
      subsection = from && from.text.match?(/\./)
      if lang == "zh"
        ret = ", 第#{from.text}" if from
        ret += "&ndash;#{to}" if to
        ret += @locality[type.to_sym]
      else
        ret = ","
        ret += @locality[type.to_sym] if subsection && type == "clause"
        ret += " #{from.text}" if from
        ret += "&ndash;#{to.text}" if to
      end
      l10n(ret)
    end

    # function localising spaces and punctuation.
    # Not clear if period needs to be localised for zh
    def l10n(x, lang = @lang, script = @script)
      if lang == "zh" && script == "Hans"
        x.gsub(/ /, "").gsub(/:/, "：").gsub(/,/, "、").
          gsub(/\(/, "（").gsub(/\)/, "）").
          gsub(/\[/, "【").gsub(/\]/, "】").
          gsub(/<b>/, "").gsub("</b>", "")
      else
        x
      end
    end
  end
end
