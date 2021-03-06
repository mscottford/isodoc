module IsoDoc
  class Metadata
    DATETYPES = %w{published accessed created implemented obsoleted confirmed
    updated issued received transmitted copied unchanged circulated}.freeze

    def ns(xpath)
      Common::ns(xpath)
    end

    def initialize(lang, script, labels)
      @metadata = {}
      DATETYPES.each { |w| @metadata["#{w}date".to_sym] = "XXX" }
      @lang = lang
      @script = script
      @c = HTMLEntities.new
      @labels = labels
    end

    def get
      @metadata
    end

    def set(key, value)
      @metadata[key] = value
    end

    def extract_person_names(authors)
      authors.inject([]) do |ret, a|
        if a.at(ns("./name/completename"))
          ret << a.at(ns("./name/completename")).text
        else
          fn = []
          forenames = a.xpath(ns("./name/forename"))
          forenames.each { |f| fn << f.text }
          surname = a&.at(ns("./name/surname"))&.text
          ret << fn.join(" ") + " " + surname
        end
      end
    end

    def extract_person_affiliations(authors)
      authors.inject([]) do |m, a|
        name = a&.at(ns("./affiliation/organization/name"))&.text
        location = a&.at(ns("./affiliation/organization/address/"\
                            "formattedAddress"))&.text
        m << ((!name.nil? && !location.nil?) ? "#{name}, #{location}" :
          (name || location || ""))
        m
      end
    end

    def extract_person_names_affiliations(authors)
      names = extract_person_names(authors)
      affils = extract_person_affiliations(authors)
      ret = {}
      affils.each_with_index do |a, i|
        ret[a] ||= []
        ret[a] << names[i]
      end
      ret
    end

    def personal_authors(isoxml)
      authors = isoxml.xpath(ns("//bibdata/contributor[role/@type = 'author' "\
                                "or xmlns:role/@type = 'editor']/person"))
      set(:authors, extract_person_names(authors))
      set(:authors_affiliations, extract_person_names_affiliations(authors))
    end

    def author(xml, _out)
      personal_authors(xml)
      agency(xml)
    end

    def bibdate(isoxml, _out)
      isoxml.xpath(ns("//bibdata/date")).each do |d|
        set("#{d['type']}date".to_sym, Common::date_range(d))
      end
    end

    def doctype(isoxml, _out)
      b = isoxml&.at(ns("//bibdata/ext/doctype"))&.text || return
      t = b.split(/[- ]/).map{ |w| w.capitalize }.join(" ")
      set(:doctype, t)
    end

    def iso?(org)
      name = org&.at(ns("./name"))&.text
      abbrev = org&.at(ns("./abbreviation"))&.text
      (abbrev == "ISO" ||
       name == "International Organization for Standardization" )
    end

    def agency(xml)
      agency = ""
      xml.xpath(ns("//bibdata/contributor[xmlns:role/@type = 'publisher']/"\
                   "organization")).each do |org|
        name = org&.at(ns("./name"))&.text
        abbrev = org&.at(ns("./abbreviation"))&.text
        agency1 = abbrev || name
        agency = iso?(org) ?  "ISO/#{agency}" : "#{agency}#{agency1}/"
      end
      set(:agency, agency.sub(%r{/$}, ""))
    end

    def docstatus(isoxml, _out)
      docstatus = isoxml.at(ns("//bibdata/status/stage"))
      set(:unpublished, true)
      if docstatus
        set(:stage, status_print(docstatus.text))
        i = isoxml&.at(ns("//bibdata/status/substage"))&.text and
          set(:substage, i)
        i = isoxml&.at(ns("//bibdata/status/iteration"))&.text and
          set(:iteration, i)
        set(:unpublished, unpublished(docstatus.text))
      end
    end

    def unpublished(status)
      !(status.downcase == "published")
    end

    def status_print(status)
      status.split(/-/).map{ |w| w.capitalize }.join(" ")
    end

    def docid(isoxml, _out)
      dn = isoxml.at(ns("//bibdata/docidentifier"))
      set(:docnumber, dn&.text)
    end

    def draftinfo(draft, revdate)
      draftinfo = ""
      if draft
        draftinfo = " (#{@labels["draft_label"]} #{draft}"
        draftinfo += ", #{revdate}" if revdate
        draftinfo += ")"
      end
      IsoDoc::Function::I18n::l10n(draftinfo, @lang, @script)
    end

    def version(isoxml, _out)
      set(:edition, isoxml&.at(ns("//bibdata/edition"))&.text)
      set(:docyear, isoxml&.at(ns("//bibdata/copyright/from"))&.text)
      set(:draft, isoxml&.at(ns("//version/draft"))&.text)
      set(:revdate, isoxml&.at(ns("//version/revision-date"))&.text)
      set(:draftinfo,
          draftinfo(get[:draft], get[:revdate]))
    end

    def title(isoxml, _out)
      main = isoxml&.at(ns("//bibdata/title[@language='en']"))&.text
      set(:doctitle, main)
    end

    def subtitle(isoxml, _out)
      nil
    end

    def relations(isoxml, _out)
      relations_obsoletes(isoxml)
      relations_partof(isoxml)
    end

    def relations_partof(isoxml)
      std = isoxml.at(ns("//bibdata/relation[@type = 'partOf']")) || return
      id = std.at(ns(".//docidentifier"))
      set(:partof, id.text) if id
    end

    def relations_obsoletes(isoxml)
      std = isoxml.at(ns("//bibdata/relation[@type = 'obsoletes']")) || return
      locality = std.at(ns(".//locality"))
      id = std.at(ns(".//docidentifier"))
      set(:obsoletes, id.text) if id
      set(:obsoletes_part, locality.text) if locality
    end

    def url(xml, _out)
      a = xml.at(ns("//bibdata/uri[not(@type)]")) and set(:url, a.text)
      a = xml.at(ns("//bibdata/uri[@type = 'html']")) and set(:html, a.text)
      a = xml.at(ns("//bibdata/uri[@type = 'xml']")) and set(:xml, a.text)
      a = xml.at(ns("//bibdata/uri[@type = 'pdf']")) and set(:pdf, a.text)
      a = xml.at(ns("//bibdata/uri[@type = 'doc']")) and set(:doc, a.text)
    end
  end
end
