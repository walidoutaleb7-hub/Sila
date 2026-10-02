import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const asyncHandler = (fn: Function) =>
  (req: Request, res: Response, next: NextFunction) =>
    Promise.resolve(fn(req, res, next)).catch(next);

// ─────────────────────────────────────
// 1. فحص حالة الخادم
// ─────────────────────────────────────
app.get('/', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    message: 'خادم صلة يعمل',
    timestamp: new Date().toISOString(),
  });
});

// ─────────────────────────────────────
// 2. إنشاء قسم جديد
// ─────────────────────────────────────
const createClassSchema = z.object({
  name: z.string().min(1).max(50),
  level: z.string().min(1).max(20),
});

app.post('/api/classes', asyncHandler(async (req: Request, res: Response) => {
  const data = createClassSchema.parse(req.body);
  const newClass = await prisma.class.create({
    data: { name: data.name, level: data.level },
  });
  res.status(201).json({ success: true, data: newClass });
}));

// ─────────────────────────────────────
// 3. جلب كل الأقسام
// ─────────────────────────────────────
app.get('/api/classes', asyncHandler(async (req: Request, res: Response) => {
  const classes = await prisma.class.findMany({
    orderBy: { createdAt: 'desc' },
    include: {
      _count: { select: { students: true } },
    },
  });
  res.json({ success: true, data: classes });
}));

// ─────────────────────────────────────
// 4. إضافة تلميذ
// ─────────────────────────────────────
const createStudentSchema = z.object({
  fullName: z.string().min(2).max(200),
});

app.post('/api/classes/:classId/students', asyncHandler(async (req: Request, res: Response) => {
  const classId = parseInt(String(req.params.classId));
  if (isNaN(classId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
    });
  }
  const data = createStudentSchema.parse(req.body);
  const existingClass = await prisma.class.findUnique({ where: { id: classId } });
  if (!existingClass) {
    return res.status(404).json({
      success: false,
      error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
    });
  }
  const student = await prisma.student.create({
    data: { fullName: data.fullName, classId },
  });
  res.status(201).json({ success: true, data: student });
}));

// ─────────────────────────────────────
// 5. جلب تلاميذ قسم
// ─────────────────────────────────────
app.get('/api/classes/:classId/students', asyncHandler(async (req: Request, res: Response) => {
  const classId = parseInt(String(req.params.classId));
  if (isNaN(classId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
    });
  }
  const students = await prisma.student.findMany({
    where: { classId },
    orderBy: { fullName: 'asc' },
  });
  res.json({ success: true, data: students });
}));

// ─────────────────────────────────────
// 6. تسجيل الحضور
// ─────────────────────────────────────
const attendanceSchema = z.object({
  classId: z.number().int().positive(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  records: z.array(z.object({
    studentId: z.number().int().positive(),
    status: z.enum(['PRESENT', 'ABSENT']),
  })).min(1),
});

app.post('/api/attendance', asyncHandler(async (req: Request, res: Response) => {
  const data = attendanceSchema.parse(req.body);
  const attendanceDate = new Date(data.date);
  const results = await prisma.$transaction(
    data.records.map((record) =>
      prisma.attendance.upsert({
        where: {
          studentId_date: { studentId: record.studentId, date: attendanceDate },
        },
        update: { status: record.status },
        create: {
          studentId: record.studentId,
          date: attendanceDate,
          status: record.status,
        },
      })
    )
  );
  res.json({ success: true, data: { saved: results.length, date: data.date } });
}));

// ─────────────────────────────────────
// 7. جلب سجل الحضور ليوم محدد
// ─────────────────────────────────────
app.get('/api/attendance', asyncHandler(async (req: Request, res: Response) => {
  const classId = parseInt(String(req.query.classId));
  const dateStr = req.query.date as string;
  if (isNaN(classId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
    });
  }
  if (!dateStr || !/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_DATE', message: 'التاريخ غير صحيح' },
    });
  }
  const attendanceDate = new Date(dateStr);
  const students = await prisma.student.findMany({
    where: { classId },
    orderBy: { fullName: 'asc' },
    include: { attendance: { where: { date: attendanceDate } } },
  });
  const result = students.map((s) => ({
    studentId: s.id,
    fullName: s.fullName,
    status: s.attendance[0]?.status || null,
  }));
  res.json({ success: true, data: { classId, date: dateStr, students: result } });
}));

// ─────────────────────────────────────
// 7.5. تعديل تلميذ
// ─────────────────────────────────────
const updateStudentSchema = z.object({
  fullName: z.string().min(2).max(200),
});

app.put('/api/students/:id', asyncHandler(async (req: Request, res: Response) => {
  const studentId = parseInt(String(req.params.id));
  if (isNaN(studentId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
    });
  }
  const data = updateStudentSchema.parse(req.body);
  const student = await prisma.student.findUnique({ where: { id: studentId } });
  if (!student) {
    return res.status(404).json({
      success: false,
      error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
    });
  }
  const updated = await prisma.student.update({
    where: { id: studentId },
    data: { fullName: data.fullName },
  });
  res.json({ success: true, data: updated });
}));

// ─────────────────────────────────────
// 7.6. حذف تلميذ
// ─────────────────────────────────────
app.delete('/api/students/:id', asyncHandler(async (req: Request, res: Response) => {
  const studentId = parseInt(String(req.params.id));
  if (isNaN(studentId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
    });
  }
  const student = await prisma.student.findUnique({ where: { id: studentId } });
  if (!student) {
    return res.status(404).json({
      success: false,
      error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
    });
  }
  await prisma.student.delete({ where: { id: studentId } });
  res.json({ success: true, data: { deletedId: studentId } });
}));

// ─────────────────────────────────────
// 7.7. إحصائيات القسم
// GET /api/classes/:id/stats
// ─────────────────────────────────────
app.get('/api/classes/:id/stats', asyncHandler(async (req: Request, res: Response) => {
  const classId = parseInt(String(req.params.id));

  if (isNaN(classId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
    });
  }

  const existingClass = await prisma.class.findUnique({
    where: { id: classId },
  });

  if (!existingClass) {
    return res.status(404).json({
      success: false,
      error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
    });
  }

  const students = await prisma.student.findMany({
    where: { classId },
    orderBy: { fullName: 'asc' },
  });

  const allAttendance = await prisma.attendance.findMany({
    where: { student: { classId } },
    orderBy: { date: 'desc' },
  });

  // ─── الإحصائيات العامة ───
  const total = allAttendance.length;
  const present = allAttendance.filter(a => a.status === 'PRESENT').length;
  const absent = allAttendance.filter(a => a.status === 'ABSENT').length;
  const overallRate = total > 0 ? Math.round((present / total) * 100) : 0;

  // ─── آخر 7 أيام ───
  const last7Days: { date: string; present: number; absent: number }[] = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateStr = d.toISOString().split('T')[0];
    const dayRecords = allAttendance.filter(a => {
      const recordDate = new Date(a.date).toISOString().split('T')[0];
      return recordDate === dateStr;
    });
    last7Days.push({
      date: dateStr,
      present: dayRecords.filter(a => a.status === 'PRESENT').length,
      absent: dayRecords.filter(a => a.status === 'ABSENT').length,
    });
  }

  // ─── إحصائيات اليوم ───
  const today = new Date().toISOString().split('T')[0];
  const todayRecords = allAttendance.filter(a => {
    const recordDate = new Date(a.date).toISOString().split('T')[0];
    return recordDate === today;
  });
  const todayPresent = todayRecords.filter(a => a.status === 'PRESENT').length;
  const todayAbsent = todayRecords.filter(a => a.status === 'ABSENT').length;

  // ─── ترتيب التلاميذ ───
  const studentStats = students.map(s => {
    const sAttendance = allAttendance.filter(a => a.studentId === s.id);
    const sPresent = sAttendance.filter(a => a.status === 'PRESENT').length;
    const sAbsent = sAttendance.filter(a => a.status === 'ABSENT').length;
    const sTotal = sAttendance.length;
    const sRate = sTotal > 0 ? Math.round((sPresent / sTotal) * 100) : 0;
    return {
      id: s.id,
      fullName: s.fullName,
      present: sPresent,
      absent: sAbsent,
      total: sTotal,
      rate: sRate,
    };
  });

  const topStudents = [...studentStats]
    .filter(s => s.total > 0)
    .sort((a, b) => b.rate - a.rate || b.present - a.present)
    .slice(0, 5);

  const worstStudents = [...studentStats]
    .filter(s => s.total > 0)
    .sort((a, b) => a.rate - b.rate || b.absent - a.absent)
    .slice(0, 5);

  res.json({
    success: true,
    data: {
      className: existingClass.name,
      classLevel: existingClass.level,
      totalStudents: students.length,
      overall: { total, present, absent, rate: overallRate },
      today: { present: todayPresent, absent: todayAbsent },
      last7Days,
      topStudents,
      worstStudents,
    },
  });
}));

// ─────────────────────────────────────
// 8. جلب سجل حضور تلميذ
// ─────────────────────────────────────
app.get('/api/students/:id/attendance', asyncHandler(async (req: Request, res: Response) => {
  const studentId = parseInt(String(req.params.id));
  if (isNaN(studentId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
    });
  }
  const student = await prisma.student.findUnique({ where: { id: studentId } });
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
      stats: { total, present, absent, rate },
      records: attendance.map(a => ({ date: a.date, status: a.status })),
    },
  });
}));

// ─────────────────────────────────────
// معالج الأخطاء
// ─────────────────────────────────────
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('خطأ:', err);
  if (err.name === 'ZodError') {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'بيانات غير صحيحة',
        details: err.errors,
      },
    });
  }
  res.status(500).json({
    success: false,
    error: { code: 'INTERNAL_ERROR', message: 'حدث خطأ في الخادم' },
  });
});

app.listen(PORT, () => {
  console.log(`✅ خادم صلة يعمل على المنفذ ${PORT}`);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});