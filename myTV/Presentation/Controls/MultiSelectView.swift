import DesignTokensKit
//
//  MultiSelectView.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import SwiftUI

struct MultiSelectView: View {

    @Binding var committedSelection: Set<String>
    @StateObject private var viewModel: MultiSelectViewModel

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        options: [String],
        selection: Binding<Set<String>>,
        allowsMultipleSelection: Bool = true,
        labelForOption: @escaping (String) -> String = { $0 },
        sortKeyForOption: @escaping (String) -> String = { $0 }
    ) {
        self._committedSelection = selection
        _viewModel = StateObject(
            wrappedValue: MultiSelectViewModel(
                title: title,
                options: options,
                initialSelection: selection.wrappedValue,
                allowsMultipleSelection: allowsMultipleSelection,
                labelForOption: labelForOption,
                sortKeyForOption: sortKeyForOption,
                haptics: AppDI.shared.getHaptics()
            )
        )
    }

    var body: some View {
        List {

            Section {
                Button("Clear", role: .destructive) { viewModel.clear() }
                    .disabled(viewModel.draftSelection.isEmpty)
            }

            // MARK: - Selected Section (Top)
            if !viewModel.selectedOptions.isEmpty {
                Section(viewModel.selectedSectionTitle) {
                    ForEach(viewModel.selectedOptions, id: \.self) { option in
                        row(option)
                    }
                }
            }

            // MARK: - All Options
            Section(viewModel.allSectionTitle) {
                ForEach(viewModel.unselectedOptions, id: \.self) { option in
                    row(option)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .screenTools()
        .tint(DesignColor.primary)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: viewModel.searchPrompt
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    committedSelection = viewModel.apply()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(!viewModel.canApply)
                .accessibilityLabel(Text(viewModel.applyButtonTitle))
            }
        }
    }
}

private extension MultiSelectView {
    // MARK: - Row

    func row(_ option: String) -> some View {
        Button {
            viewModel.toggle(option)
        } label: {
            HStack {
                Text(viewModel.labelForOption(option))
                Spacer()
                selectionIndicator(isSelected: viewModel.isSelected(option))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(viewModel.labelForOption(option)))
        .accessibilityValue(
            viewModel.isSelected(option) ? Text(VoiceOver.A11y.selected) : Text("")
        )
    }

    // MARK: - Indicator

    @ViewBuilder
    func selectionIndicator(isSelected: Bool) -> some View {
        if viewModel.allowsMultipleSelection {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignColor.primary)
                    .accessibilityHidden(true)
            }
        } else {
            Image(systemName: isSelected
                  ? "largecircle.fill.circle"
                  : "circle")
                .foregroundColor(isSelected ? DesignColor.primary : DesignColor.secondary)
                .accessibilityHidden(true)
        }
    }
}
