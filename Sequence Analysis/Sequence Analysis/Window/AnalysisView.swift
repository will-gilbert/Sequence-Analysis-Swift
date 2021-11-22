import SwiftUI

struct AnalysisView: View {
    
  @EnvironmentObject var windowState: WindowState
  @EnvironmentObject var sequenceState: SequenceState

  @State var selectedAnalysis: AnalysisView.Analyses
  
  enum Analyses: String, CaseIterable {
    case ORF = "ORF"
    case FEATURES = "Features"
    case STRUCTURE = "Structure"
    case PATTERN = "Pattern"
    case FORMAT = "Format"
    case PUBLISH = "Publish"
    case COMPOSITION = "Composition"
    case PI = "pI"
    case GIV = "GIV Editor"

    var id: Analyses { self }
  }
    
  var body: some View {
    
    windowState.selectedAnalysis = selectedAnalysis
    
    let disallowed: [Analyses] = (sequenceState.sequence.isNucleic) ?
    [.STRUCTURE, .PI] :   // Nucleic
    [.ORF, .STRUCTURE]    // Protein, Removed 'FEATURES' until we can handle very short <100 sequences
    
    // Remove any analyses not used by this sequence type
    var filteredData: [Analyses] {
      Analyses.allCases.filter({ analysis in
        disallowed.contains(analysis) == false
      })
    }
    
    return VStack {
      Picker("", selection: $selectedAnalysis) {
        ForEach(filteredData, id: \.self) { analysis in
          Text(analysis.rawValue).tag(analysis)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .font(.title)
                      
      switch selectedAnalysis {
      case .ORF:
        ORFView(sequenceState: sequenceState)
      case .FEATURES:
        FeaturesView(sequenceState: sequenceState)
      case .STRUCTURE:
        StructureView(sequenceState.sequence)
      case .PATTERN:
        PatternView(sequenceState: sequenceState)
      case .FORMAT:
        FormatView()
      case .PUBLISH:
        PublishView(sequence: sequenceState.sequence)
      case .COMPOSITION:
        CompositionView(sequence: sequenceState.sequence)
      case .PI:
        IsoElectricView(sequence: sequenceState.sequence)
      case .GIV:
        GIVView(viewModel: sequenceState.givViewModel)
      }
      Spacer()
    }
  }
}