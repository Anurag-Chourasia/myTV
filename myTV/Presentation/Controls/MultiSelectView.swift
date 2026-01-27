//
//  MultiSelectView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct MultiSelectView: View {

    let title: String
    let options: [String]
    let allowsMultipleSelection: Bool

    @Binding var committedSelection: Set<String>
    @State private var draftSelection: Set<String>
    @State private var searchText = ""

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        options: [String],
        selection: Binding<Set<String>>,
        allowsMultipleSelection: Bool = true
    ) {
        self.title = title
        self.options = options
        self._committedSelection = selection
        self.allowsMultipleSelection = allowsMultipleSelection
        _draftSelection = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        List {

            // MARK: - Selected Section (Top)
            if !selectedOptions.isEmpty {
                Section(L10n.Multiselectview.Section.selected) {
                    ForEach(selectedOptions, id: \.self) { option in
                        row(option, isSelected: true)
                    }
                }
            }

            // MARK: - All Options
            Section(L10n.Multiselectview.Section.all) {
                ForEach(unselectedOptions, id: \.self) { option in
                    row(option, isSelected: false)
                }
            }
        }
        .navigationTitle(title)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "\(L10n.App.search) \(title)"
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    apply()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(draftSelection == committedSelection)
            }
        }
    }
}

private extension MultiSelectView {

    // MARK: - Derived Data

    var filteredOptions: [String] {
        guard !searchText.isEmpty else { return options }
        return options.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedOptions: [String] {
        filteredOptions
            .filter { draftSelection.contains($0) }
            .sorted()
    }

    var unselectedOptions: [String] {
        filteredOptions
            .filter { !draftSelection.contains($0) }
            .sorted()
    }

    // MARK: - Row

    func row(_ option: String, isSelected: Bool) -> some View {
        Button {
            toggle(option)
        } label: {
            HStack {
                Text(option)
                Spacer()
                selectionIndicator(isSelected: isSelected)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

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
        AppDI.shared.getHaptics().selection()
    }

    func apply() {
        committedSelection = draftSelection
    }

    // MARK: - Indicator

    @ViewBuilder
    func selectionIndicator(isSelected: Bool) -> some View {
        if allowsMultipleSelection {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        } else {
            Image(systemName: isSelected
                  ? "largecircle.fill.circle"
                  : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
    }
}
