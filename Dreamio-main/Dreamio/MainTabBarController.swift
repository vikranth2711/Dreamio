
import UIKit

class MainTabBarController: UITabBarController {
    
    let bottomPlaybackView = BottomPlaybackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBottomPlaybackView()
    }

    private func setupBottomPlaybackView() {
        bottomPlaybackView.isHidden = true
        bottomPlaybackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomPlaybackView)

        NSLayoutConstraint.activate([
            bottomPlaybackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPlaybackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPlaybackView.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
            bottomPlaybackView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
}
