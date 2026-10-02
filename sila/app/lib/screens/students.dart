SliverAppBar(
  expandedHeight: 160,
  pinned: true,
  backgroundColor: Colors.green.shade800,
  foregroundColor: Colors.white,
  flexibleSpace: FlexibleSpaceBar(
    titlePadding:
        const EdgeInsets.only(left: 56, right: 16, bottom: 16),
    title: Text(
      widget.schoolClass.name,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.green.shade800,
            Colors.green.shade500,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Icon(
              Icons.school,
              size: 180,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.signal_cellular_alt,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'المستوى: ${widget.schoolClass.level}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  actions: [
    // ... زر الحضور
  ],
),