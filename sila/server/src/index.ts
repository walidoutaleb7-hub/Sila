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

// ═══════════════════════════════════════════
// 1. Health Check
// ═══════════════════════════════════════════
app.get('/', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    message: 'خادم صلة يعمل',
    timestamp: new Date().toISOString(),
  });
});

// ═══════════════════════════════════════════
// 2. إنشاء قسم
// ═══════════════════════════════════════════
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

// ═══════════════════════════════════════════
// 3. جلب كل الأقسام
// ═══════════════════════════════════════════
app.get('/api/classes', asyncHandler(async (req: Request, res: Response) => {
  const classes = await prisma.class.findMany({
    orderBy: { createdAt: 'desc' },
    include: { _count: { select: { students: true } } },
  });
  res.json({ success: true, data: classes });
}));

// ═══════════════════════════════════════════
// 4. إضافة تلميذ
// ═══════════════════════════════════════════
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

// ═══════════════════════════════════════════
// 5. جلب تلاميذ قسم
// ═══════════════════════════════════════════
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

// ═══════════════════════════════════════════
// 6. تسجيل الحضور
// ═══════════════════════════════════════════
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
        where: { studentId_date: { studentId: record.studentId, date: attendanceDate } },
        update: { status: record.status },
        create: { studentId: record.studentId, date: attendanceDate, status: record.status },
      })
    )
  );
  res.json({ success: true, data: { saved: results.length, date: data.date } });
}));

// ═══════════════════════════════════════════
// 7. جلب سجل الحضور ليوم
// ═══════════════════════════════════════════
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

// ═══════════════════════════════════════════
// 7.5. تعديل تلميذ
// ═══════════════════════════════════════════
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

// ═══════════════════════════════════════════
// 7.6. حذف تلميذ
// ═══════════════════════════════════════════
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

// ═══════════════════════════════════════════
// 7.7. إحصائيات القسم
// ═══════════════════════════════════════════
app.get('/api/classes/:id/stats', asyncHandler(async (req: Request, res: Response) => {
  const classId = parseInt(String(req.params.id));
  if (isNaN(classId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
    });
  }
  const existingClass = await prisma.class.findUnique({ where: { id: classId } });
  if (!existingClass) {
    return res.status(404).json({
      success: false,
      error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
    });
  }

  const students = await prisma.student.findMany({ where: { classId }, orderBy: { fullName: 'asc' } });
  const allAttendance = await prisma.attendance.findMany({
    where: { student: { classId } },
    orderBy: { date: 'desc' },
  });

  const total = allAttendance.length;
  const present = allAttendance.filter(a => a.status === 'PRESENT').length;
  const absent = allAttendance.filter(a => a.status === 'ABSENT').length;
  const overallRate = total > 0 ? Math.round((present / total) * 100) : 0;

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

  const today = new Date().toISOString().split('T')[0];
  const todayRecords = allAttendance.filter(a => {
    const recordDate = new Date(a.date).toISOString().split('T')[0];
    return recordDate === today;
  });

  const studentStats = students.map(s => {
    const sAttendance = allAttendance.filter(a => a.studentId === s.id);
    const sPresent = sAttendance.filter(a => a.status === 'PRESENT').length;
    const sAbsent = sAttendance.filter(a => a.status === 'ABSENT').length;
    const sTotal = sAttendance.length;
    const sRate = sTotal > 0 ? Math.round((sPresent / sTotal) * 100) : 0;
    return { id: s.id, fullName: s.fullName, present: sPresent, absent: sAbsent, total: sTotal, rate: sRate };
  });

  const topStudents = [...studentStats].filter(s => s.total > 0)
    .sort((a, b) => b.rate - a.rate || b.present - a.present).slice(0, 5);
  const worstStudents = [...studentStats].filter(s => s.total > 0)
    .sort((a, b) => a.rate - b.rate || b.absent - a.absent).slice(0, 5);

  res.json({
    success: true,
    data: {
      className: existingClass.name,
      classLevel: existingClass.level,
      totalStudents: students.length,
      overall: { total, present, absent, rate: overallRate },
      today: {
        present: todayRecords.filter(a => a.status === 'PRESENT').length,
        absent: todayRecords.filter(a => a.status === 'ABSENT').length,
      },
      last7Days,
      topStudents,
      worstStudents,
    },
  });
}));

// ═══════════════════════════════════════════
// 7.8. إضافة/تحديث دفعة درجات
// ═══════════════════════════════════════════
const bulkGradeSchema = z.object({
  classId: z.number().int().positive(),
  assessment: z.string().min(1).max(50),
  maxScore: z.number().positive().default(20),
  coeff: z.number().int().positive().default(1),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  note: z.string().max(500).optional(),
  records: z.array(z.object({
    studentId: z.number().int().positive(),
    score: z.number().min(0).max(1000),
  })).min(1),
});

app.post('/api/grades', asyncHandler(async (req: Request, res: Response) => {
  const data = bulkGradeSchema.parse(req.body);
  const gradeDate = new Date(data.date);

  await prisma.grade.deleteMany({
    where: {
      classId: data.classId,
      assessment: data.assessment,
      date: gradeDate,
      studentId: { in: data.records.map(r => r.studentId) },
    },
  });

  const results = await prisma.$transaction(
    data.records.map((r) =>
      prisma.grade.create({
        data: {
          studentId: r.studentId,
          classId: data.classId,
          assessment: data.assessment,
          maxScore: data.maxScore,
          coeff: data.coeff,
          date: gradeDate,
          score: r.score,
          note: data.note,
        },
      })
    )
  );

  res.json({ success: true, data: { saved: results.length } });
}));

// ═══════════════════════════════════════════
// 7.9. جلب درجات القسم (ملخص الجلسات)
// ═══════════════════════════════════════════
app.get('/api/classes/:id/grades', asyncHandler(async (req: Request, res: Response) => {
  const classId = parseInt(String(req.params.id));
  if (isNaN(classId)) {
    return res.status(400).json({
      success: false,
      error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
    });
  }

  const grades = await prisma.grade.findMany({
    where: { classId },
    orderBy: [{ date: 'desc' }, { assessment: 'asc' }],
  });

  const grouped: { [key: string]: any } = {};
  for (const g of grades) {
    const key = `${g.assessment}__${g.date.toISOString().split('T')[0]}`;
    if (!grouped[key]) {
      grouped[key] = {
        assessment: g.assessment,
        date: g.date,
        maxScore: g.maxScore,
        coeff: g.coeff,
        note: g.note,
        count: 0,
        avg: 0,
        totalScore: 0,
      };
    }
    grouped[key].count++;
    grouped[key].totalScore += g.score;
  }

  const sessions = Object.values(grouped).map((s: any) => ({
    assessment: s.assessment,
    date: s.date,
    maxScore: s.maxScore,
    coeff: s.coeff,
    note: s.note,
    count: s.count,
    avg: s.count > 0 ? Math.round((s.totalScore / s.count) * 100) / 100 : 0,
  }));

  res.json({ success: true, data: { sessions } });
}));

// ═══════════════════════════════════════════
// 7.9.5. جلب درجات جلسة محددة
// ═══════════════════════════════════════════
app.get('/api/grades/session', asyncHandler(async (req: Request, res: Response) => {
  const classId = parseInt(String(req.query.classId));
  const assessment = req.query.assessment as string;
  const dateStr = req.query.date as string;

  if (isNaN(classId) || !assessment || !dateStr) {
    return res.status(400).json({
      success: false,
      error: { code: 'MISSING_PARAMS', message: 'معاملات ناقصة' },
    });
  }

  const gradeDate = new Date(dateStr);

  const grades = await prisma.grade.findMany({
    where: {
      classId,
      assessment,
      date: gradeDate,
    },
    include: {
      student: {
        select: { id: true, fullName: true },
      },
    },
    orderBy: { student: { fullName: 'asc' } },
  });

  const records = grades.map(g => ({
    studentId: g.studentId,
    fullName: g.student.fullName,
    score: g.score,
    maxScore: g.maxScore,
    coeff: g.coeff,
    note: g.note,
  }));

  res.json({
    success: true,
    data: {
      assessment,
      date: dateStr,
      maxScore: grades[0]?.maxScore ?? 20,
      coeff: grades[0]?.coeff ?? 1,
      note: grades[0]?.note ?? null,
      records,
    },
  });
}));

// ═══════════════════════════════════════════
// 7.10. جلب درجات تلميذ
// ═══════════════════════════════════════════
app.get('/api/students/:id/grades', asyncHandler(async (req: Request, res: Response) => {
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

  const grades = await prisma.grade.findMany({
    where: { studentId },
    orderBy: { date: 'desc' },
  });

  let totalWeighted = 0;
  let totalCoeff = 0;
  for (const g of grades) {
    const pct = g.score / g.maxScore;
    totalWeighted += pct * g.coeff;
    totalCoeff += g.coeff;
  }
  const average = totalCoeff > 0
    ? Math.round((totalWeighted / totalCoeff) * 20 * 100) / 100
    : 0;

  const byAssessment: { [key: string]: { total: number; sum: number; count: number } } = {};
  for (const g of grades) {
    if (!byAssessment[g.assessment]) {
      byAssessment[g.assessment] = { total: 0, sum: 0, count: 0 };
    }
    byAssessment[g.assessment].sum += (g.score / g.maxScore) * 20;
    byAssessment[g.assessment].count++;
  }
  const assessmentAverages = Object.entries(byAssessment).map(([k, v]) => ({
    assessment: k,
    avg: v.count > 0 ? Math.round((v.sum / v.count) * 100) / 100 : 0,
    count: v.count,
  }));

  res.json({
    success: true,
    data: {
      student: {
        id: student.id,
        fullName: student.fullName,
        classId: student.classId,
      },
      average: average,
      count: grades.length,
      assessmentAverages,
      records: grades.map(g => ({
        id: g.id,
        assessment: g.assessment,
        score: g.score,
        maxScore: g.maxScore,
        coeff: g.coeff,
        date: g.date,
        note: g.note,
      })),
    },
  });
}));

// ═══════════════════════════════════════════
// 8. جلب سجل حضور تلميذ
// ═══════════════════════════════════════════
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
      student: { id: student.id, fullName: student.fullName, classId: student.classId },
      stats: { total, present, absent, rate },
      records: attendance.map(a => ({ date: a.date, status: a.status })),
    },
  });
}));

// ═══════════════════════════════════════════
// معالج الأخطاء
// ═══════════════════════════════════════════
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