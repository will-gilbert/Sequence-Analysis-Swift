//
//  FetchFromNCBI.swift
//  Sequence Analysis
//
//  Created by Will Gilbert on 10/20/21.
//

// https://www.youtube.com/watch?v=Ahrix9JsaIU
//
// https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?db=nucleotide&id=NM_000485.2&rettype=fasta
// https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?db=protein&id=NP_061820.1&rettype=fasta
//
// https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?db=nucleotide&id=NM_000485.2&retmode=xml
// https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?db=nucleotide&id=NM_000485.2&retmode=json //This is ASN.1

// >NP_061820.1 cytochrome c [Homo sapiens]
// MGDVEKGKKIFIMKCSQCHTVEKGGKHKTGPNLHGLFGRKTGQAPGYSYTAANKNKGIIWGEDTLMEYLE
// NPKKYIPGTKMIFVGIKKKEERADLIAYLKKATNE

import SwiftUI

struct FetchFromNCBI {

  var appState : AppState

  func createWindow(width: CGFloat, height: CGFloat) -> NSWindow {
    
    return NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: width, height: height),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )

  }

  func newSequence() {
    
    let window = createWindow(width: 0, height: 0)
    let contents = NCBIFetchView(appState: appState, window: window)
    let _ = WindowController(window: window, contents: AnyView(contents))
    
    NSApp.runModal(for: window)
  }
}
    


  // https://developer.apple.com/documentation/appkit/nswindow
  struct NCBIFetchView: View {
    
    var appState : AppState
    var window: NSWindow

    @State var entrezID: String = ""
    @State var sequenceType: SequenceType = SequenceType.DNA

    @State private var alertIsShowing = false
    @State var errorMsg: String = ""

        
    let types = [SequenceType.DNA, SequenceType.PROTEIN]
    
    var body: some View {
                  
     return Group {
        
        Section(header: SectionHeader(name: "Fetch from the NCBI")) {
          Text("")
        }
        
        Section {
            HStack {
            Text("Entrez ID")
            TextField("NM_000485.2", text: $entrezID)
          }
          Text("Examples: NM_000485 NP_061820 11128019")
            .font(.footnote)
        }

        Section {
            Picker("Database", selection: $sequenceType) {
              Text("Nucleic").tag(SequenceType.DNA)
              Text("Protein").tag(SequenceType.PROTEIN)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        Divider()
        Spacer(minLength: 10)
                
        Section {
          HStack {
            Spacer()
            // C A N C E L  ============================
            Button(action: {
              window.close()
            }) {
              Text("Cancel")
            }.keyboardShortcut(.cancelAction)

            // O K  =====================================
            Button(action: {
              
              var urlString: String = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch?"
              urlString.append("db=")
              urlString.append( sequenceType == .DNA ? "nucleotide" : "protein" )
              urlString.append("&id=")
//              urlString.append("NM_000485")
              urlString.append(entrezID)
              urlString.append("&retmode=xml")
                            
              if let url = URL(string: urlString) {
                do {
                  let contents = try String(contentsOf: url)
                  let xmlDocument = try XMLDocument(xmlString: contents)
                  let parser = NCBI_XMLParser()
                  parser.parse(xmlDocument: xmlDocument)
                  if let string = parser.sequenceString {
                    let title = parser.sequenceTitle ?? "Untitled"
                    let sequence = Sequence(string.uppercased(), uid: entrezID, title: title, type: sequenceType)
                    let _ = appState.addSequence(sequence)
                  } else if let error = parser.errorMsg {
                    alertIsShowing = true
                    errorMsg = error
                    errorMsg.append("\n\nTry the ")
                    errorMsg.append( sequenceType == .DNA ? "Protein" : "Nucleic" )
                    errorMsg.append(" database.")
                  }
                  
                } catch {
                  alertIsShowing = true
                  errorMsg = "Contents could not be loaded"
                }
              } else {
                alertIsShowing = true
                errorMsg = "Bad URL"
              }
              
              window.close()

            }) {
              Text("OK")
            }
            .keyboardShortcut(.defaultAction)
          }
          .alert(isPresented: $alertIsShowing) {
            Alert(title: Text("Fetch from NCBI"), message: Text(errorMsg), dismissButton: .default(Text("OK")))
          }
        }
      }
      .padding(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
      .frame(width: 500, height: 275)
    }

  struct SectionHeader: View {
    var name: String
    var body: some View {
      Text(name)
        .font(.largeTitle)
    }
    
    
  }
}

class NCBI_XMLParser: NSObject, XMLParserDelegate {

  var currentElement: String = ""
  var sequenceString: String? = nil
  var sequenceTitle: String? = nil
  var errorMsg: String? = nil

  func parse(xmlDocument: XMLDocument) {
            
    let parser = XMLParser(data: xmlDocument.xmlData)
    parser.delegate = self
    let success = parser.parse()
    
    if success == false {
      if let error = parser.parserError {
        print("error:\(error)")
      } else {
        print("error: nil")
      }
    }
  }
  
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    currentElement = elementName
  }
  
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    
    let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    if data.isEmpty == false {
      switch currentElement {
      case "GBSeq_sequence": sequenceString = data
      case "GBSeq_definition":
        sequenceTitle = data
      case "ERROR":
        errorMsg = data
        if let error = errorMsg {
          if let range = error.range(of: "proxy_stream():") {
            errorMsg = String(error[range.upperBound...])
          }
        }
      default:
        break
      }
    }
  }
}

/*
 
 <?xml version="1.0" encoding="UTF-8" ?>
 <!DOCTYPE eEfetchResult PUBLIC "-//NLM//DTD efetch 20131226//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20131226/efetch.dtd">
 <eFetchResult>
   <ERROR> Error: CEFetchPApplication::proxy_stream(): Failed to retrieve sequence: 11128019
 </ERROR>
 </eFetchResult>
 
 <?xml version="1.0" encoding="UTF-8"  ?>
 <!DOCTYPE GBSet PUBLIC "-//NCBI//NCBI GBSeq/EN" "https://www.ncbi.nlm.nih.gov/dtd/NCBI_GBSeq.dtd">
 <GBSet>
   <GBSeq>

     <GBSeq_locus>NP_061820</GBSeq_locus>
     <GBSeq_length>105</GBSeq_length>
     <GBSeq_moltype>AA</GBSeq_moltype>
     <GBSeq_topology>linear</GBSeq_topology>
     <GBSeq_division>PRI</GBSeq_division>
     <GBSeq_update-date>29-JUN-2021</GBSeq_update-date>
     <GBSeq_create-date>09-NOV-2000</GBSeq_create-date>
     <GBSeq_definition>cytochrome c [Homo sapiens]</GBSeq_definition>
     <GBSeq_primary-accession>NP_061820</GBSeq_primary-accession>
     <GBSeq_accession-version>NP_061820.1</GBSeq_accession-version>
     <GBSeq_other-seqids>
       <GBSeqid>ref|NP_061820.1|</GBSeqid>
       <GBSeqid>gi|11128019</GBSeqid>
     </GBSeq_other-seqids>
     <GBSeq_keywords>
       <GBKeyword>RefSeq</GBKeyword>
       <GBKeyword>MANE Select</GBKeyword>
     </GBSeq_keywords>
     <GBSeq_source>Homo sapiens (human)</GBSeq_source>
     <GBSeq_organism>Homo sapiens</GBSeq_organism>
     <GBSeq_taxonomy>Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Hominidae; Homo</GBSeq_taxonomy>
     <GBSeq_references>
       <GBReference>
         <GBReference_reference>1</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Chen F</GBAuthor>
           <GBAuthor>Yin S</GBAuthor>
           <GBAuthor>Luo B</GBAuthor>
           <GBAuthor>Wu X</GBAuthor>
           <GBAuthor>Yan H</GBAuthor>
           <GBAuthor>Yan D</GBAuthor>
           <GBAuthor>Chen C</GBAuthor>
           <GBAuthor>Guan F</GBAuthor>
           <GBAuthor>Yuan J</GBAuthor>
         </GBReference_authors>
         <GBReference_title>VDAC1 Conversely Correlates with Cytc Expression and Predicts Poor Prognosis in Human Breast Cancer Patients</GBReference_title>
         <GBReference_journal>Oxid Med Cell Longev 2021, 7647139 (2021)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1155/2021/7647139</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>33680287</GBReference_pubmed>
         <GBReference_remark>GeneRIF: VDAC1 Conversely Correlates with Cytc Expression and Predicts Poor Prognosis in Human Breast Cancer Patients.; Publication Status: Online-Only</GBReference_remark>
       </GBReference>
       <GBReference>
         <GBReference_reference>2</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Fellner M</GBAuthor>
           <GBAuthor>Parakra R</GBAuthor>
           <GBAuthor>McDonald KO</GBAuthor>
           <GBAuthor>Kass I</GBAuthor>
           <GBAuthor>Jameson GNL</GBAuthor>
           <GBAuthor>Wilbanks SM</GBAuthor>
           <GBAuthor>Ledgerwood EC</GBAuthor>
         </GBReference_authors>
         <GBReference_title>Altered structure and dynamics of pathogenic cytochrome c variants correlate with increased apoptotic activity</GBReference_title>
         <GBReference_journal>Biochem J 478 (3), 669-684 (2021)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1042/BCJ20200793</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>33480393</GBReference_pubmed>
         <GBReference_remark>GeneRIF: Altered structure and dynamics of pathogenic cytochrome c variants correlate with increased apoptotic activity.</GBReference_remark>
       </GBReference>
       <GBReference>
         <GBReference_reference>3</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Bacellar C</GBAuthor>
           <GBAuthor>Kinschel D</GBAuthor>
           <GBAuthor>Mancini GF</GBAuthor>
           <GBAuthor>Ingle RA</GBAuthor>
           <GBAuthor>Rouxel J</GBAuthor>
           <GBAuthor>Cannelli O</GBAuthor>
           <GBAuthor>Cirelli C</GBAuthor>
           <GBAuthor>Knopp G</GBAuthor>
           <GBAuthor>Szlachetko J</GBAuthor>
           <GBAuthor>Lima FA</GBAuthor>
           <GBAuthor>Menzi S</GBAuthor>
           <GBAuthor>Pamfilidis G</GBAuthor>
           <GBAuthor>Kubicek K</GBAuthor>
           <GBAuthor>Khakhulin D</GBAuthor>
           <GBAuthor>Gawelda W</GBAuthor>
           <GBAuthor>Rodriguez-Fernandez A</GBAuthor>
           <GBAuthor>Biednov M</GBAuthor>
           <GBAuthor>Bressler C</GBAuthor>
           <GBAuthor>Arrell CA</GBAuthor>
           <GBAuthor>Johnson PJM</GBAuthor>
           <GBAuthor>Milne CJ</GBAuthor>
           <GBAuthor>Chergui M</GBAuthor>
         </GBReference_authors>
         <GBReference_title>Spin cascade and doming in ferric hemes: Femtosecond X-ray absorption and X-ray emission studies</GBReference_title>
         <GBReference_journal>Proc Natl Acad Sci U S A 117 (36), 21914-21920 (2020)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1073/pnas.2009490117</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>32848065</GBReference_pubmed>
         <GBReference_remark>GeneRIF: Spin cascade and doming in ferric hemes: Femtosecond X-ray absorption and X-ray emission studies.</GBReference_remark>
       </GBReference>
       <GBReference>
         <GBReference_reference>4</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Haenig C</GBAuthor>
           <GBAuthor>Atias N</GBAuthor>
           <GBAuthor>Taylor AK</GBAuthor>
           <GBAuthor>Mazza A</GBAuthor>
           <GBAuthor>Schaefer MH</GBAuthor>
           <GBAuthor>Russ J</GBAuthor>
           <GBAuthor>Riechers SP</GBAuthor>
           <GBAuthor>Jain S</GBAuthor>
           <GBAuthor>Coughlin M</GBAuthor>
           <GBAuthor>Fontaine JF</GBAuthor>
           <GBAuthor>Freibaum BD</GBAuthor>
           <GBAuthor>Brusendorf L</GBAuthor>
           <GBAuthor>Zenkner M</GBAuthor>
           <GBAuthor>Porras P</GBAuthor>
           <GBAuthor>Stroedicke M</GBAuthor>
           <GBAuthor>Schnoegl S</GBAuthor>
           <GBAuthor>Arnsburg K</GBAuthor>
           <GBAuthor>Boeddrich A</GBAuthor>
           <GBAuthor>Pigazzini L</GBAuthor>
           <GBAuthor>Heutink P</GBAuthor>
           <GBAuthor>Taylor JP</GBAuthor>
           <GBAuthor>Kirstein J</GBAuthor>
           <GBAuthor>Andrade-Navarro MA</GBAuthor>
           <GBAuthor>Sharan R</GBAuthor>
           <GBAuthor>Wanker EE</GBAuthor>
         </GBReference_authors>
         <GBReference_title>Interactome Mapping Provides a Network of Neurodegenerative Disease Proteins and Uncovers Widespread Protein Aggregation in Affected Brains</GBReference_title>
         <GBReference_journal>Cell Rep 32 (7), 108050 (2020)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1016/j.celrep.2020.108050</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>32814053</GBReference_pubmed>
       </GBReference>
       <GBReference>
         <GBReference_reference>5</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Zhang Z</GBAuthor>
           <GBAuthor>Gerstein M</GBAuthor>
         </GBReference_authors>
         <GBReference_title>The human genome has 49 cytochrome c pseudogenes, including a relic of a primordial gene that still functions in mouse</GBReference_title>
         <GBReference_journal>Gene 312, 61-72 (2003)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1016/s0378-1119(03)00579-1</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>12909341</GBReference_pubmed>
       </GBReference>
       <GBReference>
         <GBReference_reference>6</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Lynch SR</GBAuthor>
           <GBAuthor>Sherman D</GBAuthor>
           <GBAuthor>Copeland RA</GBAuthor>
         </GBReference_authors>
         <GBReference_title>Cytochrome c binding affects the conformation of cytochrome a in cytochrome c oxidase</GBReference_title>
         <GBReference_journal>J Biol Chem 267 (1), 298-302 (1992)</GBReference_journal>
         <GBReference_pubmed>1309738</GBReference_pubmed>
       </GBReference>
       <GBReference>
         <GBReference_reference>7</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Garber EA</GBAuthor>
           <GBAuthor>Margoliash E</GBAuthor>
         </GBReference_authors>
         <GBReference_title>Interaction of cytochrome c with cytochrome c oxidase: an understanding of the high- to low-affinity transition</GBReference_title>
         <GBReference_journal>Biochim Biophys Acta 1015 (2), 279-287 (1990)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1016/0005-2728(90)90032-y</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>2153405</GBReference_pubmed>
       </GBReference>
       <GBReference>
         <GBReference_reference>8</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Evans MJ</GBAuthor>
           <GBAuthor>Scarpulla RC</GBAuthor>
         </GBReference_authors>
         <GBReference_title>The human somatic cytochrome c gene: two classes of processed pseudogenes demarcate a period of rapid molecular evolution</GBReference_title>
         <GBReference_journal>Proc Natl Acad Sci U S A 85 (24), 9625-9629 (1988)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1073/pnas.85.24.9625</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>2849112</GBReference_pubmed>
       </GBReference>
       <GBReference>
         <GBReference_reference>9</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Bedetti,C.D.</GBAuthor>
         </GBReference_authors>
         <GBReference_title>Immunocytochemical demonstration of cytochrome c oxidase with an immunoperoxidase method: a specific stain for mitochondria in formalin-fixed and paraffin-embedded human tissues</GBReference_title>
         <GBReference_journal>J Histochem Cytochem 33 (5), 446-452 (1985)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1177/33.5.2580882</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>2580882</GBReference_pubmed>
       </GBReference>
       <GBReference>
         <GBReference_reference>10</GBReference_reference>
         <GBReference_position>1..105</GBReference_position>
         <GBReference_authors>
           <GBAuthor>Ng,S.</GBAuthor>
           <GBAuthor>Smith,M.B.</GBAuthor>
           <GBAuthor>Smith,H.T.</GBAuthor>
           <GBAuthor>Millett,F.</GBAuthor>
         </GBReference_authors>
         <GBReference_title>Effect of modification of individual cytochrome c lysines on the reaction with cytochrome b5</GBReference_title>
         <GBReference_journal>Biochemistry 16 (23), 4975-4978 (1977)</GBReference_journal>
         <GBReference_xref>
           <GBXref>
             <GBXref_dbname>doi</GBXref_dbname>
             <GBXref_id>10.1021/bi00642a006</GBXref_id>
           </GBXref>
         </GBReference_xref>
         <GBReference_pubmed>199233</GBReference_pubmed>
       </GBReference>
     </GBSeq_references>
     <GBSeq_comment>REVIEWED REFSEQ: This record has been curated by NCBI staff. The reference sequence was derived from DB447825.1, BC024216.1, AC007487.2 and AI365318.1.; ~Summary: This gene encodes a small heme protein that functions as a central component of the electron transport chain in mitochondria. The encoded protein associates with the inner membrane of the mitochondrion where it accepts electrons from cytochrome b and transfers them to the cytochrome oxidase complex. This protein is also involved in initiation of apoptosis. Mutations in this gene are associated with autosomal dominant nonsyndromic thrombocytopenia. Numerous processed pseudogenes of this gene are found throughout the human genome.[provided by RefSeq, Jul 2010].; ~Sequence Note: This RefSeq record was created from transcript and genomic sequence data to make the sequence consistent with the reference genome assembly. The genomic coordinates used for the transcript record were based on transcript alignments.; ~Publication Note: This RefSeq record includes a subset of the publications that are available for this gene. Please see the Gene record to access additional publications.; ; ##Evidence-Data-START## ; Transcript exon combination :: AL713681.1, BC009582.1 [ECO:0000332] ; ##Evidence-Data-END##; ; ##RefSeq-Attributes-START## ; gene product(s) localized to mito. :: reported by MitoCarta ; MANE Ensembl match :: ENST00000305786.7/ ENSP00000307786.2 ; RefSeq Select criteria :: based on single protein-coding transcript ; ##RefSeq-Attributes-END##</GBSeq_comment>
     <GBSeq_source-db>REFSEQ: accession NM_018947.6</GBSeq_source-db>
     <GBSeq_feature-table>
       <GBFeature>
         <GBFeature_key>source</GBFeature_key>
         <GBFeature_location>1..105</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_from>1</GBInterval_from>
             <GBInterval_to>105</GBInterval_to>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>organism</GBQualifier_name>
             <GBQualifier_value>Homo sapiens</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>db_xref</GBQualifier_name>
             <GBQualifier_value>taxon:9606</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>chromosome</GBQualifier_name>
             <GBQualifier_value>7</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>map</GBQualifier_name>
             <GBQualifier_value>7p15.3</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
       <GBFeature>
         <GBFeature_key>Protein</GBFeature_key>
         <GBFeature_location>1..105</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_from>1</GBInterval_from>
             <GBInterval_to>105</GBInterval_to>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>product</GBQualifier_name>
             <GBQualifier_value>cytochrome c</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>calculated_mol_wt</GBQualifier_name>
             <GBQualifier_value>11618</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
       <GBFeature>
         <GBFeature_key>Region</GBFeature_key>
         <GBFeature_location>1..103</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_from>1</GBInterval_from>
             <GBInterval_to>103</GBInterval_to>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>region_name</GBQualifier_name>
             <GBQualifier_value>Cyc7</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>note</GBQualifier_name>
             <GBQualifier_value>Cytochrome c2 [Energy production and conversion]; COG3474</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>db_xref</GBQualifier_name>
             <GBQualifier_value>CDD:226005</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
       <GBFeature>
         <GBFeature_key>Site</GBFeature_key>
         <GBFeature_location>2</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_point>2</GBInterval_point>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>site_type</GBQualifier_name>
             <GBQualifier_value>acetylation</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>note</GBQualifier_name>
             <GBQualifier_value>N-acetylglycine. /evidence=ECO:0000269|PubMed:13933734; propagated from UniProtKB/Swiss-Prot (P99999.2)</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
       <GBFeature>
         <GBFeature_key>Site</GBFeature_key>
         <GBFeature_location>49</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_point>49</GBInterval_point>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>site_type</GBQualifier_name>
             <GBQualifier_value>phosphorylation</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>note</GBQualifier_name>
             <GBQualifier_value>Phosphotyrosine. /evidence=ECO:0000250|UniProtKB:P62894; propagated from UniProtKB/Swiss-Prot (P99999.2)</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
       <GBFeature>
         <GBFeature_key>Site</GBFeature_key>
         <GBFeature_location>73</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_point>73</GBInterval_point>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>site_type</GBQualifier_name>
             <GBQualifier_value>acetylation</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>note</GBQualifier_name>
             <GBQualifier_value>N6-acetyllysine, alternate. /evidence=ECO:0000250|UniProtKB:P62897; propagated from UniProtKB/Swiss-Prot (P99999.2)</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
       <GBFeature>
         <GBFeature_key>Site</GBFeature_key>
         <GBFeature_location>98</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_point>98</GBInterval_point>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>site_type</GBQualifier_name>
             <GBQualifier_value>phosphorylation</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>note</GBQualifier_name>
             <GBQualifier_value>Phosphotyrosine. /evidence=ECO:0000250|UniProtKB:P62894; propagated from UniProtKB/Swiss-Prot (P99999.2)</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
       <GBFeature>
         <GBFeature_key>Site</GBFeature_key>
         <GBFeature_location>100</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_point>100</GBInterval_point>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>site_type</GBQualifier_name>
             <GBQualifier_value>acetylation</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>note</GBQualifier_name>
             <GBQualifier_value>N6-acetyllysine. /evidence=ECO:0000250|UniProtKB:P62897; propagated from UniProtKB/Swiss-Prot (P99999.2)</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
       <GBFeature>
         <GBFeature_key>CDS</GBFeature_key>
         <GBFeature_location>1..105</GBFeature_location>
         <GBFeature_intervals>
           <GBInterval>
             <GBInterval_from>1</GBInterval_from>
             <GBInterval_to>105</GBInterval_to>
             <GBInterval_accession>NP_061820.1</GBInterval_accession>
           </GBInterval>
         </GBFeature_intervals>
         <GBFeature_quals>
           <GBQualifier>
             <GBQualifier_name>gene</GBQualifier_name>
             <GBQualifier_value>CYCS</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>gene_synonym</GBQualifier_name>
             <GBQualifier_value>CYC; HCS; THC4</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>coded_by</GBQualifier_name>
             <GBQualifier_value>NM_018947.6:70..387</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>transl_table</GBQualifier_name>
             <GBQualifier_value>1</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>db_xref</GBQualifier_name>
             <GBQualifier_value>CCDS:CCDS5393.1</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>db_xref</GBQualifier_name>
             <GBQualifier_value>GeneID:54205</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>db_xref</GBQualifier_name>
             <GBQualifier_value>HGNC:HGNC:19986</GBQualifier_value>
           </GBQualifier>
           <GBQualifier>
             <GBQualifier_name>db_xref</GBQualifier_name>
             <GBQualifier_value>MIM:123970</GBQualifier_value>
           </GBQualifier>
         </GBFeature_quals>
       </GBFeature>
     </GBSeq_feature-table>
     <GBSeq_sequence>mgdvekgkkifimkcsqchtvekggkhktgpnlhglfgrktgqapgysytaanknkgiiwgedtlmeylenpkkyipgtkmifvgikkkeeradliaylkkatne</GBSeq_sequence>
   </GBSeq>

 </GBSet>
 
 
 
 */
