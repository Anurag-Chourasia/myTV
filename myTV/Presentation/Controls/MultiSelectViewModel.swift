//
//  MultiSelectViewModel.swift
//  myTV
//
//  Created by Anurag Chourasia on 08/02/26.
//

import Foundation
import Combine

@MainActor
final class MultiSelectViewModel: ObservableObject {
    let title: String
    let options: [String]
    let allowsMultipleSelection: Bool
    let labelForOption: (String) -> String
    let sortKeyForOption: (String) -> String

    @Published var searchText = ""
    @Published private(set) var draftSelection: Set<String>

    private let haptics: HapticService
    private var originalSelection: Set<String>

    init(
        title: String,
        options: [String],
        initialSelection: Set<String>,
        allowsMultipleSelection: Bool,
        labelForOption: @escaping (String) -> String,
        sortKeyForOption: @escaping (String) -> String,
        haptics: HapticService
    ) {
        self.title = title
        self.options = options
        self.originalSelection = initialSelection
        self.draftSelection = initialSelection
        self.allowsMultipleSelection = allowsMultipleSelection
        self.labelForOption = labelForOption
        self.sortKeyForOption = sortKeyForOption
        self.haptics = haptics
    }

    var canApply: Bool {
        draftSelection != originalSelection
    }

    var selectedSectionTitle: String {
        Localizable.Multiselectview.Section.selected
    }

    var allSectionTitle: String {
        Localizable.Multiselectview.Section.all
    }

    var applyButtonTitle: String {
        Localizable.App.apply
    }

    var searchPrompt: String {
        "\(Localizable.App.search) \(title)"
    }

    var selectedOptions: [String] {
        filteredOptions
            .filter { draftSelection.contains($0) }
            .sorted(by: compareOptions)
    }

    var unselectedOptions: [String] {
        filteredOptions
            .filter { !draftSelection.contains($0) }
            .sorted(by: compareOptions)
    }

    func isSelected(_ option: String) -> Bool {
        draftSelection.contains(option)
    }

    func toggle(_ option: String) {
        if allowsMultipleSelection {
            if draftSelection.contains(option) {
                draftSelection.remove(option)
            } else {
                draftSelection.insert(option)
            }
        } else {
            draftSelection = [option]
        }
        haptics.selection()
    }

    func apply() -> Set<String> {
        originalSelection = draftSelection
        return draftSelection
    }
}

private extension MultiSelectViewModel {
    var filteredOptions: [String] {
        guard !searchText.isEmpty else { return options }
        return options.filter {
            labelForOption($0).localizedCaseInsensitiveContains(searchText)
        }
    }

    func compareOptions(_ lhs: String, _ rhs: String) -> Bool {
        sortKeyForOption(lhs)
            .localizedCaseInsensitiveCompare(sortKeyForOption(rhs)) == .orderedAscending
    }
}
