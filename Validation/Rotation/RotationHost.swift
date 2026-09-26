import UIKit

@main
final class RotationAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Rotation", sessionRole: session.role)
        configuration.delegateClass = RotationSceneDelegate.self
        return configuration
    }
}

final class RotationSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: scene)
        window?.rootViewController = ProcessInfo.processInfo.arguments.contains("ui-rotation") ? RotationHostController() : UIViewController()
        window?.makeKeyAndVisible()
    }
}

final class RotatingBrowser: JXPhotoBrowserViewController {
    var rotating = false
    var resizeAction: (() -> Void)?
    var rotateOnDragEnd = false
    var rotationTrigger = "idle"
    var preservedPage = -1
    var rotateDuringDrag = false
    var phase = "idle"
    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        rotating = true
        let cv = collectionView
        phase = cv.isDecelerating ? "decelerating" : (cv.isDragging ? "dragging" : "idle")
        let offset = scrollDirection == .horizontal ? cv.contentOffset.x / cv.bounds.width : cv.contentOffset.y / cv.bounds.height
        preservedPage = realIndex(fromVirtual: Int(offset.rounded()))
        super.viewWillTransition(to: size, with: coordinator)
        let action = resizeAction
        resizeAction = nil
        if let action = action { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: action) }
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in self?.rotating = false }
    }
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        if rotateOnDragEnd {
            rotateOnDragEnd = false
            rotationTrigger = decelerate ? "decelerating" : "dragged"
            // UIKit updates isDragging/isDecelerating after returning from this callback.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.rotateLandscape() }
        }
    }
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        if rotateDuringDrag {
            rotateDuringDrag = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.rotateLandscape() }
        }
    }
    func rotateLandscape() {
        if #available(iOS 16, *) {
            view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        }
    }
}

final class RotationHostController: UIViewController, JXPhotoBrowserDelegate {
    let browser = RotatingBrowser()
    let status = UILabel()
    var count = 5
    var timer: Timer?
    var images: [UIImage] = []
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let args = ProcessInfo.processInfo.arguments
        for index in 0..<5 {
            images.append(UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400)).image { context in
                UIColor(hue: CGFloat(index) / 5, saturation: 0.65, brightness: 0.75, alpha: 1).setFill()
                context.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
                UIColor.white.setStroke()
                for x in stride(from: 0, through: 600, by: 50) {
                    let line = UIBezierPath()
                    line.move(to: CGPoint(x: x, y: 0)); line.addLine(to: CGPoint(x: x, y: 400)); line.stroke()
                }
                ("PAGE \(index)" as NSString).draw(at: CGPoint(x: 115, y: 145), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 80), .foregroundColor: UIColor.white])
            })
        }
        browser.delegate = self
        browser.isLoopingEnabled = !args.contains("nonloop")
        browser.scrollDirection = args.contains("vertical") ? .vertical : .horizontal
        browser.itemSpacing = 20
        browser.transitionType = .none
        browser.isDismissGestureEnabled = false
        browser.initialIndex = args.contains("last") ? 4 : 0
        addChild(browser)
        view.addSubview(browser.view)
        browser.didMove(toParent: self)
        browser.view.translatesAutoresizingMaskIntoConstraints = false
        browser.collectionView.accessibilityIdentifier = "photos"
        let controls = UIStackView()
        controls.axis = .horizontal
        controls.distribution = .fillEqually
        for (title, selector) in [("Far", #selector(far)), ("Auto", #selector(autoplay)), ("Reload", #selector(reload)), ("Jump", #selector(jump)), ("Drag", #selector(armDrag))] {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.accessibilityIdentifier = title
            button.addTarget(self, action: selector, for: .touchUpInside)
            controls.addArrangedSubview(button)
        }
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)
        status.accessibilityIdentifier = "status"
        status.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        status.numberOfLines = 2
        status.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(status)
        NSLayoutConstraint.activate([
            controls.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            controls.leadingAnchor.constraint(equalTo: view.leadingAnchor), controls.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controls.heightAnchor.constraint(equalToConstant: 44),
            browser.view.topAnchor.constraint(equalTo: controls.bottomAnchor), browser.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            browser.view.trailingAnchor.constraint(equalTo: view.trailingAnchor), browser.view.bottomAnchor.constraint(equalTo: status.topAnchor),
            status.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8), status.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            status.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor), status.heightAnchor.constraint(equalToConstant: 36)
        ])
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateStatus() }
    }
    deinit { timer?.invalidate() }
    @objc func far() {
        browser.scrollToPage(at: 4, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { self.browser.rotateLandscape() }
    }
    @objc func autoplay() {
        browser.autoPlayInterval = 0.7
        browser.isAutoPlayEnabled.toggle()
    }
    @objc func reload() {
        browser.scrollToPage(at: 4, animated: false)
        browser.resizeAction = { [weak self] in
            guard let self = self else { return }
            self.count = 2
            self.browser.reloadData()
        }
    }
    @objc func jump() {
        browser.scrollToPage(at: 4, animated: false)
        browser.resizeAction = { [weak self] in self?.browser.scrollToPage(at: 1, animated: true) }
    }
    @objc func armDrag() {
        if ProcessInfo.processInfo.arguments.contains("dragging") {
            browser.rotateDuringDrag = true
        } else {
            browser.rotateOnDragEnd = true
        }
    }
    func numberOfItems(in browser: JXPhotoBrowserViewController) -> Int { count }
    func photoBrowser(_ browser: JXPhotoBrowserViewController, cellForItemAt index: Int, at indexPath: IndexPath) -> JXPhotoBrowserAnyCell {
        let cell = browser.dequeueReusableCell(withReuseIdentifier: JXZoomImageCell.reuseIdentifier, for: indexPath) as! JXZoomImageCell
        cell.imageView.image = images[index]
        cell.doubleTapZoomScale = ProcessInfo.processInfo.arguments.contains("fixedzoom") ? 2 : nil
        cell.accessibilityIdentifier = "page-\(index)"
        return cell
    }
    func updateStatus() {
        let cv = browser.collectionView
        let virtual = browser.scrollDirection == .horizontal ? cv.contentOffset.x / cv.bounds.width : cv.contentOffset.y / cv.bounds.height
        let visible = cv.indexPathsForVisibleItems.min { lhs, rhs in abs(Double(lhs.item) - Double(virtual)) < abs(Double(rhs.item) - Double(virtual)) }
        let aligned = abs(virtual - virtual.rounded()) < 0.002
        let zoom = browser.visibleZoomImageCell()?.scrollView.zoomScale ?? 0
        let imageWidth = browser.visibleZoomImageCell()?.imageView.frame.width ?? 0
        let imageHeight = browser.visibleZoomImageCell()?.imageView.frame.height ?? 0
        let fitted = imageWidth <= browser.view.bounds.width + 1 && imageHeight <= browser.view.bounds.height + 1
        status.text = "page=\(browser.pageIndex);visible=\((visible?.item ?? 0) % max(1, count));aligned=\(aligned ? 1 : 0);zoom=\(String(format: "%.2f", zoom));fit=\(fitted ? 1 : 0);landscape=\(view.bounds.width > view.bounds.height ? 1 : 0);transition=\(browser.rotating ? 1 : 0);count=\(count);trigger=\(browser.rotationTrigger);preserved=\(browser.preservedPage);phase=\(browser.phase)"
    }
}
