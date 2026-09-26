import UIKit

final class LifecycleHostController: UIViewController, JXPhotoBrowserDelegate {
    private var browser: JXPhotoBrowserViewController?
    private let rootStatus = UILabel()
    private let browserStatus = UILabel()
    private let coverStatus = UILabel()
    private var thumbnails: [UIImageView] = []
    private var timer: Timer?
    private var dragCount = 0
    private var dragging = false
    private var dragPage = 0
    private var movedDuringDrag = false
    private var resumed = false
    private let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400)).image { c in
        UIColor.systemBlue.setFill()
        c.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let open = UIButton(type: .system)
        open.setTitle("Open", for: .normal)
        open.addTarget(self, action: #selector(openBrowser), for: .touchUpInside)
        open.frame = CGRect(x: 20, y: 80, width: 100, height: 44)
        view.addSubview(open)
        for index in 0..<5 {
            let thumbnail = UIImageView(image: image)
            thumbnail.frame = CGRect(x: 20 + index * 60, y: 150, width: 50, height: 50)
            view.addSubview(thumbnail)
            thumbnails.append(thumbnail)
        }
        rootStatus.frame = CGRect(x: 10, y: 220, width: 350, height: 40)
        rootStatus.accessibilityIdentifier = "lifecycleRoot"
        view.addSubview(rootStatus)
        browserStatus.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        browserStatus.textColor = .white
        browserStatus.numberOfLines = 0
        browserStatus.accessibilityIdentifier = "lifecycleStatus"
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in self?.updateStatus() }
    }
    deinit { timer?.invalidate() }

    @objc private func openBrowser() {
        dragCount = 0
        dragging = false
        movedDuringDrag = false
        resumed = false
        let browser = JXPhotoBrowserViewController()
        self.browser = browser
        browser.delegate = self
        browser.transitionType = .zoom
        browser.isLoopingEnabled = false
        browser.register(LifecycleImageCell.self, forReuseIdentifier: "lifecycle")
        browser.collectionView.accessibilityIdentifier = "lifecyclePhotos"
        browser.loadViewIfNeeded()
        browserStatus.translatesAutoresizingMaskIntoConstraints = false
        browser.view.addSubview(browserStatus)
        let autoplay = UIButton(type: .system)
        autoplay.setTitle("Auto", for: .normal)
        autoplay.addTarget(self, action: #selector(enableAutoplay), for: .touchUpInside)
        autoplay.translatesAutoresizingMaskIntoConstraints = false
        browser.view.addSubview(autoplay)
        NSLayoutConstraint.activate([
            autoplay.topAnchor.constraint(equalTo: browser.view.safeAreaLayoutGuide.topAnchor),
            autoplay.leadingAnchor.constraint(equalTo: browser.view.leadingAnchor, constant: 20),
            autoplay.widthAnchor.constraint(equalToConstant: 100), autoplay.heightAnchor.constraint(equalToConstant: 44),
            browserStatus.leadingAnchor.constraint(equalTo: browser.view.leadingAnchor, constant: 10),
            browserStatus.trailingAnchor.constraint(equalTo: browser.view.trailingAnchor, constant: -10),
            browserStatus.bottomAnchor.constraint(equalTo: browser.view.safeAreaLayoutGuide.bottomAnchor),
            browserStatus.heightAnchor.constraint(equalToConstant: 70)
        ])
        if ProcessInfo.processInfo.arguments.contains("navigation-container") {
            browser.navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeContainer)),
                UIBarButtonItem(title: "Animated", style: .plain, target: self, action: #selector(closeContainerAnimated)),
                UIBarButtonItem(title: "Cover", style: .plain, target: self, action: #selector(showCover))
            ]
            let navigation = UINavigationController(rootViewController: browser)
            navigation.modalPresentationStyle = .fullScreen
            present(navigation, animated: false)
        } else {
            browser.present(from: self)
        }
    }

    @objc private func closeContainer() { dismiss(animated: false) }
    @objc private func closeContainerAnimated() { dismiss(animated: true) }

    @objc private func showCover() {
        let cover = UIViewController()
        cover.modalPresentationStyle = .fullScreen
        cover.view.backgroundColor = .white
        let back = UIButton(type: .system)
        back.setTitle("Return", for: .normal)
        back.frame = CGRect(x: 20, y: 80, width: 100, height: 44)
        back.addTarget(self, action: #selector(hideCover), for: .touchUpInside)
        cover.view.addSubview(back)
        coverStatus.frame = CGRect(x: 20, y: 150, width: 300, height: 44)
        coverStatus.accessibilityIdentifier = "coverStatus"
        cover.view.addSubview(coverStatus)
        browser?.present(cover, animated: false)
    }

    @objc private func hideCover() { browser?.presentedViewController?.dismiss(animated: false) }

    @objc private func enableAutoplay() {
        browser?.autoPlayInterval = 1.5
        browser?.isAutoPlayEnabled = true
    }

    func numberOfItems(in browser: JXPhotoBrowserViewController) -> Int { thumbnails.count }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, thumbnailViewAt index: Int) -> UIView? { thumbnails[index] }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = browser.dequeueReusableCell(withReuseIdentifier: "lifecycle", for: indexPath) as! LifecycleImageCell
        cell.imageView.image = image
        cell.doubleTapZoomScale = 2
        cell.interactionChanged = { [weak self, weak browser] active in
            guard let self = self else { return }
            self.dragging = active
            if active {
                self.dragCount += 1
                self.dragPage = browser?.pageIndex ?? 0
            }
        }
        return cell
    }

    private func updateStatus() {
        rootStatus.text = "closed=\(presentedViewController == nil ? 1 : 0);restored=\(thumbnails.allSatisfy { !$0.isHidden } ? 1 : 0)"
        guard let browser = browser else { return }
        coverStatus.text = "hidden=\(thumbnails.filter { $0.isHidden }.count)"
        if dragging && browser.pageIndex != dragPage { movedDuringDrag = true }
        if !dragging && dragCount > 0 && browser.pageIndex != dragPage { resumed = true }
        let zoom = browser.visibleZoomImageCell()?.scrollView.zoomScale ?? 1
        browserStatus.text = "page=\(browser.pageIndex);dragCount=\(dragCount);dragging=\(dragging ? 1 : 0);moved=\(movedDuringDrag ? 1 : 0);resumed=\(resumed ? 1 : 0);scroll=\(browser.collectionView.isScrollEnabled ? 1 : 0);zoom=\(String(format: "%.2f", zoom))"
    }
}

final class LifecycleImageCell: JXZoomImageCell {
    var interactionChanged: ((Bool) -> Void)?
    override func photoBrowserDismissInteractionDidChange(isInteracting: Bool) {
        super.photoBrowserDismissInteractionDidChange(isInteracting: isInteracting)
        interactionChanged?(isInteracting)
    }
}
