import Foundation

enum JXPhotoBrowserPaging {
    static func centeredVirtualIndex(for realIndex: Int, count: Int, loopMultiplier: Int) -> Int {
        (loopMultiplier / 2) * count + realIndex
    }

    static func normalizedInitialIndex(_ index: Int, count: Int, looping: Bool) -> Int {
        guard count > 0 else { return 0 }
        if looping {
            return ((index % count) + count) % count
        }
        return max(0, min(index, count - 1))
    }

    static func nearestVirtualIndex(
        for realIndex: Int,
        near currentVirtual: Int,
        count: Int,
        virtualCount: Int
    ) -> Int {
        guard count > 0, virtualCount > 0 else { return 0 }

        let currentBlock = currentVirtual / count
        let candidates = (currentBlock - 1...currentBlock + 1)
            .map { $0 * count + realIndex }
            .filter { (0..<virtualCount).contains($0) }

        return candidates.min { lhs, rhs in
            let lhsDistance = abs(lhs - currentVirtual)
            let rhsDistance = abs(rhs - currentVirtual)
            return lhsDistance == rhsDistance ? lhs < rhs : lhsDistance < rhsDistance
        } ?? max(0, min(realIndex, virtualCount - 1))
    }
}
