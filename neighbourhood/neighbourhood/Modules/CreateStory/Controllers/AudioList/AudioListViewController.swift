//
//  AudioListViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 28.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

private enum Defaults {
    static let maxAudioFileSize = 20 * 1000 * 1000 // 20MB
    static let maxAudioDuration: Double = 300 // 5m
}

protocol AudioListViewControllerDelegate: class {
    func trackSelected(_ track: AudioTrackModel)
}

class AudioListViewController: BaseViewController {

    @IBOutlet weak var addTrackView: UIView!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTextView: UITextField!
    @IBOutlet weak var tracksTableView: UITableView!
    @IBOutlet weak var discoverButton: UIButton!
    @IBOutlet weak var myTracksButton: UIButton!
    @IBOutlet weak var favoritesButton: UIButton!
    @IBOutlet weak var addTrackButton: UIButton!

    private let viewModel = AudioListViewModel()
    private var isSearchOpen = false {
        didSet { updateSearchState() }
    }

    private lazy var emptyView: EmptyView = {
        let emptyView = EmptyView()
        emptyView.isHidden = true
        emptyView.frame = CGRect(x: 16, y: tracksTableView.contentOffset.y + 4, width: view.frame.width - 32, height: 80)
        tracksTableView.backgroundView = emptyView
        emptyView.setAttributesForEmptyScreen(text: R.string.localizable.noAudioFound())
        return emptyView
    }()


    public weak var delegate: AudioListViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFilterButtons()
        setupTableView()
        setupSearchView()
        setupViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioPlayerService.shared.stop()
    }

    @IBAction func didTapBack(_ sender: Any) {
        close()
    }

    @IBAction func didTapSearch(_ sender: Any) {
        isSearchOpen.toggle()
    }

    @IBAction func didTapDiscover(_ sender: Any) {
        changeFilter(filter: .discover)
    }

    @IBAction func didTapMyTracks(_ sender: Any) {
        changeFilter(filter: .myTracks)
    }

    @IBAction func didTapFavorites(_ sender: Any) {
        changeFilter(filter: .favorites)
    }

    @IBAction func didTapAddTrack(_ sender: Any) {
        openFilePicker()
    }
}

// MARK: - Configuration

extension AudioListViewController {

    private func setupFilterButtons() {
        for button in [discoverButton, myTracksButton, favoritesButton].compactMap({$0}) {
            button.setBackgroundColor(color: R.color.greyBackground()!.withAlphaComponent(0.5), forState: .normal)
            button.setBackgroundColor(color: R.color.blueButton()!, forState: .disabled)
            button.setTitleColor(R.color.mainBlack(), for: .normal)
            button.setTitleColor(.white, for: .disabled)
        }
    }

    private func setupTableView() {
        tracksTableView.register(R.nib.audioTrackCell)
        tracksTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
        tracksTableView.estimatedRowHeight = 82
    }

    private func setupSearchView() {
        searchTextView.addTarget(self, action: #selector(handleTextFieldChange(_:)), for: .editingChanged)
    }

    private func setupViewModel() {
        viewModel.$filter.bind { [weak self] (filter) in
            self?.updateFiltersButton(filter: filter)
        }

        viewModel.$tracks.bind { [weak self] (tracks) in
            self?.tracksTableView.reloadData()
            self?.emptyView.isHidden = tracks.count > 0
        }
    }
}

// MARK: - Private methods

extension AudioListViewController {
    private func updateFiltersButton(filter: AudioListViewModel.Filter) {
        discoverButton.isEnabled = filter != .discover
        myTracksButton.isEnabled = filter != .myTracks
        favoritesButton.isEnabled = filter != .favorites
    }

    private func close() {
        navigationController?.popViewController(animated: true)
    }

    private func updateSearchState() {
        searchView.isHidden = !isSearchOpen
        addTrackView.isHidden = isSearchOpen
    }

    public func changeFilter(filter: AudioListViewModel.Filter) {
        viewModel.changeFilter(filter)
    }

    private func openFilePicker() {
        let pickerController = UIDocumentPickerViewController(documentTypes: GlobalConstants.Common.audioTypes, in: .import)
        pickerController.delegate = self
        pickerController.modalPresentationStyle = .overCurrentContext
        present(pickerController, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension AudioListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.audioTrackCell, for: indexPath)!
        cell.track = viewModel.tracks[indexPath.row]
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.cellForRow(at: indexPath)?.isSelected = true
        tableView.endUpdates()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.cellForRow(at: indexPath)?.isSelected = false
        tableView.endUpdates()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.tracks.count - 1 {
            viewModel.loadMore()
        }
    }

}

// MARK: - AudioTrackCellDelegate

extension AudioListViewController: AudioTrackCellDelegate {
    func trackSelected(_ track: AudioTrackModel) {
        close()
        delegate?.trackSelected(track)
    }

    func trackFavoriteToggled(track: AudioTrackModel) {
        viewModel.toggleFollowed(track: track)
    }

    func trackMorePressed(track: AudioTrackModel) {
        let controller = EntityMenuController(entity: track)
        controller.onMenuSelected = { [weak self] (type, track) in
            guard let self = self else {
                return
            }
            switch type {
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: track)
            default:
                break
            }
        }
        present(controller.alertController, animated: true)
    }
}

// MARK: - Handle searchTextField changes

extension AudioListViewController {
    @objc private func handleTextFieldChange(_ textField: UITextField) {
        if let text = textField.text, text.count > 1 {
            viewModel.search(query: text)
        } else {
            viewModel.clearSearch()
        }
    }
}


// MARK: - UIDocumentPickerDelegate

extension AudioListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            guard let fileSize = resources.fileSize, fileSize < Defaults.maxAudioFileSize else {
                Toast.show(message: Alert.ErrorMessage.audioTooBig)
                return
            }
        } catch {
            return
        }
        if AVAsset(url: url).duration.seconds > Defaults.maxAudioDuration {
            Toast.show(message: Alert.ErrorMessage.audioTooLong)
            return
        }
        CreateStoryRouter(in: self.navigationController).openAddTrack(for: url)
    }
}
