// ─────────────────────────────────────
// 8. جلب سجل حضور تلميذ
// GET /api/students/:id/attendance
// ─────────────────────────────────────
app.get('/api/students/:id/attendance', asyncHandler(async (req: Request, res: Response) => {
  const studentId = parseInt(String(req.params.id));
  
  if (isNaN(studentId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
    });
  }

  const student = await prisma.student.findUnique({
    where: { id: studentId },
  });

  if (!student) {
    return res.status(404).json({
      success: false,
      error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
    });
  }

  const attendance = await prisma.attendance.findMany({
    where: { studentId },
    orderBy: { date: 'desc' },
  });

  const total = attendance.length;
  const present = attendance.filter(a => a.status === 'PRESENT').length;
  const absent = attendance.filter(a => a.status === 'ABSENT').length;
  const rate = total > 0 ? Math.round((present / total) * 100) : 0;

  res.json({
    success: true,
    data: {
      student: {
        id: student.id,
        fullName: student.fullName,
        classId: student.classId,
      },
      stats: {
        total,
        present,
        absent,
        rate,
      },
      records: attendance.map(a => ({
        date: a.date,
        status: a.status,
      })),
    },
  });
}));