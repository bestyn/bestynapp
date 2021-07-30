//
//  HashtagViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 22.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

class HashtagViewController: BasePostListViewController {

    @IBOutlet weak var hashtagLabel: UILabel!
    @IBOutlet weak var topBarView: UIView!

    private var hashtag: String

    init(hashtag: String) {
        self.hashtag = hashtag.replacingOccurrences(of: "#", with: "")
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        topBarView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 16)
        hashtagLabel.text = "#\(hashtag)"
    }

    @IBAction func didTapBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override var emptyViewTitle: String {
        return ""
    }

    override func fetchPosts() -> PreparedOperation<[PostModel]> {
        return postsManager.postsByHashtag(hashtag, page: nextPage)
    }
}
