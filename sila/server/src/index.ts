import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';
import { z } from 'zod';

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;
const JWT_SECRET =
  process.env.JWT_SECRET || 'sila-secret-change-me-in-production-2026';
const TOKEN_EXPIRY = '30d';

app.use(cors());
app.use(express.json({ limit: '5mb' }));

const asyncHandler = (fn: Function) =>
  (req: Request, res: Response, next: NextFunction) =>
    Promise.resolve(fn(req, res, next)).catch(next);

interface AuthRequest extends Request {
  userId?: string;
}

// ═══════════════════════════════════════════
// Middleware: JWT
// ═══════════════════════════════════════════
const authenticate = asyncHandler(
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: { code: 'NO_TOKEN', message: 'يجب تسجيل الدخول' },
      });
    }

    const token = authHeader.substring(7);
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as { userId: string };
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
      });
      if (!user) {
        return res.status(401).json({
          success: false,
          error: { code: 'USER_NOT_FOUND', message: 'الحساب غير موجود' },
        });
      }
      req.userId = user.id;
      next();
    } catch (err) {
      return res.status(401).json({
        success: false,
        error: { code: 'INVALID_TOKEN', message: 'جلسة منتهية' },
      });
    }
  },
);

// ═══════════════════════════════════════════
// 1. Health
// ═══════════════════════════════════════════
app.get('/', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    message: 'خادم صلة يعمل',
    timestamp: new Date().toISOString(),
  });
});

// ═══════════════════════════════════════════
// 2. المصادقة
// ═══════════════════════════════════════════
const registerSchema = z.object({
  email: z.string().email().max(150),
  password: z.string().min(6).max(100),
  fullName: z.string().min(2).max(200),
  schoolName: z.string().max(200).optional().nullable(),
  securityQuestion: z.string().min(5).max(200).optional().nullable(),
  securityAnswer: z.string().min(2).max(200).optional().nullable(),
});

app.post(
  '/api/auth/register',
  asyncHandler(async (req: Request, res: Response) => {
    const data = registerSchema.parse(req.body);

    const existing = await prisma.user.findUnique({
      where: { email: data.email.toLowerCase() },
    });
    if (existing) {
      return res.status(409).json({
        success: false,
        error: { code: 'EMAIL_EXISTS', message: 'هذا البريد مستخدم مسبقاً' },
      });
    }

    const passwordHash = await bcrypt.hash(data.password, 10);

    let securityAnswerHash: string | null = null;
    if (data.securityAnswer && data.securityAnswer.trim().length >= 2) {
      securityAnswerHash = await bcrypt.hash(
        data.securityAnswer.trim().toLowerCase(),
        10,
      );
    }

    const user = await prisma.user.create({
      data: {
        email: data.email.toLowerCase(),
        passwordHash,
        fullName: data.fullName,
        schoolName: data.schoolName || null,
        securityQuestion: data.securityQuestion?.trim() || null,
        securityAnswerHash,
      },
    });

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, {
      expiresIn: TOKEN_EXPIRY,
    });

    res.status(201).json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          schoolName: user.schoolName,
        },
      },
    });
  }),
);

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

app.post(
  '/api/auth/login',
  asyncHandler(async (req: Request, res: Response) => {
    const data = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: data.email.toLowerCase() },
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'البريد أو كلمة المرور غير صحيحة',
        },
      });
    }

    const ok = await bcrypt.compare(data.password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'البريد أو كلمة المرور غير صحيحة',
        },
      });
    }

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, {
      expiresIn: TOKEN_EXPIRY,
    });

    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          schoolName: user.schoolName,
        },
      },
    });
  }),
);

app.post(
  '/api/auth/security-question',
  asyncHandler(async (req: Request, res: Response) => {
    const data = z.object({ email: z.string().email() }).parse(req.body);
    const user = await prisma.user.findUnique({
      where: { email: data.email.toLowerCase() },
    });
    if (!user || !user.securityQuestion) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'لا يوجد حساب بهذا البريد، أو لم يُسجَّل سؤال أمان',
        },
      });
    }
    res.json({ success: true, data: { question: user.securityQuestion } });
  }),
);

const resetPasswordSchema = z.object({
  email: z.string().email(),
  answer: z.string().min(1).max(200),
  newPassword: z.string().min(6).max(100),
});

app.post(
  '/api/auth/reset-password',
  asyncHandler(async (req: Request, res: Response) => {
    const data = resetPasswordSchema.parse(req.body);
    const user = await prisma.user.findUnique({
      where: { email: data.email.toLowerCase() },
    });
    if (!user || !user.securityAnswerHash) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'الحساب غير موجود' },
      });
    }
    const cleanAnswer = data.answer.trim().toLowerCase();
    const ok = await bcrypt.compare(cleanAnswer, user.securityAnswerHash);
    if (!ok) {
      return res.status(401).json({
        success: false,
        error: { code: 'WRONG_ANSWER', message: 'الجواب غير صحيح' },
      });
    }
    const newHash = await bcrypt.hash(data.newPassword, 10);
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: newHash },
    });
    res.json({
      success: true,
      data: { message: 'تم تغيير كلمة المرور بنجاح' },
    });
  }),
);

app.get(
  '/api/auth/me',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const user = await prisma.user.findUnique({
      where: { id: req.userId! },
    });
    if (!user) {
      return res.status(404).json({
        success: false,
        error: { code: 'USER_NOT_FOUND', message: 'الحساب غير موجود' },
      });
    }
    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        schoolName: user.schoolName,
      },
    });
  }),
);

const updateMeSchema = z.object({
  fullName: z.string().min(2).max(200).optional(),
  schoolName: z.string().max(200).optional().nullable(),
});

app.put(
  '/api/auth/me',
  authenticate,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const data = updateMeSchema.parse(req.body);
    const user = await prisma.user.update({
      where: { id: req.userId! },
      data: {
        fullName: data.fullName,
        schoolName: data.schoolName,
      },
    });
    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        schoolName: user.schoolName,
      },
    });
  }),
);

// ═══════════════════════════════════════════
// كل ما يلي يتطلب تسجيل دخول
// ═══════════════════════════════════════════
app.use('/api', (req, res, next) => {
  if (req.path === '/auth/register' || req.path === '/auth/login') {
    return next();
  }
  return authenticate(req, res, next);
});

// ═══════════════════════════════════════════
// أدوات التحقق من الملكية
// ═══════════════════════════════════════════
async function ownsClass(classId: number, userId: string): Promise<boolean> {
  const c = await prisma.class.findFirst({
    where: { id: classId, userId },
  });
  return c !== null;
}

async function ownsStudent(studentId: number, userId: string): Promise<boolean> {
  const s = await prisma.student.findFirst({
    where: { id: studentId, class: { userId } },
  });
  return s !== null;
}

// ═══════════════════════════════════════════
// 3. الأقسام
// ═══════════════════════════════════════════
const createClassSchema = z.object({
  name: z.string().min(1).max(50),
  level: z.string().min(1).max(20),
});

app.post(
  '/api/classes',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const data = createClassSchema.parse(req.body);
    const newClass = await prisma.class.create({
      data: { name: data.name, level: data.level, userId: req.userId! },
    });
    res.status(201).json({ success: true, data: newClass });
  }),
);

app.get(
  '/api/classes',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classes = await prisma.class.findMany({
      where: { userId: req.userId! },
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { students: true } } },
    });
    res.json({ success: true, data: classes });
  }),
);

// ═══════════════════════════════════════════
// 4. التلاميذ
// ═══════════════════════════════════════════
const createStudentSchema = z.object({
  fullName: z.string().min(2).max(200),
  guardianName: z.string().max(200).optional().nullable(),
  guardianPhone: z.string().max(30).optional().nullable(),
});

app.post(
  '/api/classes/:classId/students',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.classId));
    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }
    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }
    const data = createStudentSchema.parse(req.body);
    const student = await prisma.student.create({
      data: {
        fullName: data.fullName,
        classId,
        guardianName: data.guardianName || null,
        guardianPhone: data.guardianPhone || null,
      },
    });
    res.status(201).json({ success: true, data: student });
  }),
);

function computeConsecutiveAbsences(
  records: { date: Date; period: string; status: string }[],
): number {
  if (records.length === 0) return 0;

  const byDay = new Map<string, { hasPresent: boolean; hasAbsent: boolean }>();
  for (const r of records) {
    const key = new Date(r.date).toISOString().split('T')[0];
    if (!byDay.has(key)) {
      byDay.set(key, { hasPresent: false, hasAbsent: false });
    }
    const day = byDay.get(key)!;
    if (r.status === 'PRESENT') day.hasPresent = true;
    if (r.status === 'ABSENT') day.hasAbsent = true;
  }

  const sortedDays = [...byDay.entries()].sort((a, b) => (a[0] > b[0] ? -1 : 1));

  let count = 0;
  let prevDate: Date | null = null;
  for (const [dateStr, day] of sortedDays) {
    const isFullAbsenceDay = day.hasAbsent && !day.hasPresent;
    if (!isFullAbsenceDay) break;

    const d = new Date(dateStr);
    if (prevDate !== null) {
      const diffDays = Math.round(
        (prevDate.getTime() - d.getTime()) / (1000 * 60 * 60 * 24),
      );
      if (diffDays !== 1) break;
    }
    count++;
    prevDate = d;
  }
  return count;
}

app.get(
  '/api/classes/:classId/students',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.classId));
    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }
    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    const students = await prisma.student.findMany({
      where: { classId },
      orderBy: { fullName: 'asc' },
      include: {
        attendance: {
          orderBy: { date: 'desc' },
          take: 20,
        },
      },
    });

    const result = students.map((s) => ({
      id: s.id,
      fullName: s.fullName,
      classId: s.classId,
      photoUrl: s.photoUrl,
      guardianName: s.guardianName,
      guardianPhone: s.guardianPhone,
      consecutiveAbsences: computeConsecutiveAbsences(s.attendance),
    }));

    res.json({ success: true, data: result });
  }),
);

// ═══════════════════════════════════════════
// 5. الحضور (مع period)
// ═══════════════════════════════════════════
const attendanceSchema = z.object({
  classId: z.number().int().positive(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  period: z.enum(['MORNING', 'AFTERNOON']),
  records: z
    .array(
      z.object({
        studentId: z.number().int().positive(),
        status: z.enum(['PRESENT', 'ABSENT']),
      }),
    )
    .min(1),
});

app.post(
  '/api/attendance',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const data = attendanceSchema.parse(req.body);

    if (!(await ownsClass(data.classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    const attendanceDate = new Date(data.date);
    const results = await prisma.$transaction(
      data.records.map((record) =>
        prisma.attendance.upsert({
          where: {
            studentId_date_period: {
              studentId: record.studentId,
              date: attendanceDate,
              period: data.period,
            },
          },
          update: { status: record.status },
          create: {
            studentId: record.studentId,
            date: attendanceDate,
            period: data.period,
            status: record.status,
          },
        }),
      ),
    );
    res.json({
      success: true,
      data: {
        saved: results.length,
        date: data.date,
        period: data.period,
      },
    });
  }),
);

app.get(
  '/api/attendance',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.query.classId));
    const dateStr = req.query.date as string;
    const period = req.query.period as string;

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
    if (!period || !['MORNING', 'AFTERNOON'].includes(period)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_PERIOD', message: 'الفترة غير صحيحة' },
      });
    }

    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    const attendanceDate = new Date(dateStr);
    const students = await prisma.student.findMany({
      where: { classId },
      orderBy: { fullName: 'asc' },
      include: {
        attendance: {
          where: { date: attendanceDate, period },
        },
      },
    });
    const result = students.map((s) => ({
      studentId: s.id,
      fullName: s.fullName,
      photoUrl: s.photoUrl,
      guardianPhone: s.guardianPhone,
      status: s.attendance[0]?.status || null,
    }));
    res.json({
      success: true,
      data: { classId, date: dateStr, period, students: result },
    });
  }),
);

// ═══════════════════════════════════════════
// 6. تعديل/حذف تلميذ
// ═══════════════════════════════════════════
const updateStudentSchema = z.object({
  fullName: z.string().min(2).max(200),
  guardianName: z.string().max(200).optional().nullable(),
  guardianPhone: z.string().max(30).optional().nullable(),
});

app.put(
  '/api/students/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const studentId = parseInt(String(req.params.id));
    if (isNaN(studentId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
      });
    }
    if (!(await ownsStudent(studentId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
      });
    }
    const data = updateStudentSchema.parse(req.body);
    const student = await prisma.student.findUnique({
      where: { id: studentId },
    });
    if (!student) {
      return res.status(404).json({
        success: false,
        error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
      });
    }
    const updated = await prisma.student.update({
      where: { id: studentId },
      data: {
        fullName: data.fullName,
        guardianName:
          data.guardianName !== undefined
            ? data.guardianName || null
            : student.guardianName,
        guardianPhone:
          data.guardianPhone !== undefined
            ? data.guardianPhone || null
            : student.guardianPhone,
      },
    });
    res.json({ success: true, data: updated });
  }),
);

app.put(
  '/api/students/:id/photo',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const studentId = parseInt(String(req.params.id));
    if (isNaN(studentId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
      });
    }
    if (!(await ownsStudent(studentId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
      });
    }
    const data = z
      .object({
        photoUrl: z.string().min(1).max(5_000_000),
      })
      .parse(req.body);
    const updated = await prisma.student.update({
      where: { id: studentId },
      data: { photoUrl: data.photoUrl },
    });
    res.json({ success: true, data: updated });
  }),
);

app.delete(
  '/api/students/:id/photo',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const studentId = parseInt(String(req.params.id));
    if (isNaN(studentId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
      });
    }
    if (!(await ownsStudent(studentId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
      });
    }
    const updated = await prisma.student.update({
      where: { id: studentId },
      data: { photoUrl: null },
    });
    res.json({ success: true, data: updated });
  }),
);

app.delete(
  '/api/students/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const studentId = parseInt(String(req.params.id));
    if (isNaN(studentId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
      });
    }
    if (!(await ownsStudent(studentId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
      });
    }
    await prisma.student.delete({ where: { id: studentId } });
    res.json({ success: true, data: { deletedId: studentId } });
  }),
);

// ═══════════════════════════════════════════
// 7. إحصائيات القسم (قديمة - للتوافق)
// ═══════════════════════════════════════════
app.get(
  '/api/classes/:id/stats',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.id));
    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }

    const existingClass = await prisma.class.findFirst({
      where: { id: classId, userId: req.userId! },
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

    const total = allAttendance.length;
    const present = allAttendance.filter((a) => a.status === 'PRESENT').length;
    const absent = allAttendance.filter((a) => a.status === 'ABSENT').length;
    const overallRate = total > 0 ? Math.round((present / total) * 100) : 0;

    const last7Days: { date: string; present: number; absent: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const dayRecords = allAttendance.filter((a) => {
        const recordDate = new Date(a.date).toISOString().split('T')[0];
        return recordDate === dateStr;
      });
      last7Days.push({
        date: dateStr,
        present: dayRecords.filter((a) => a.status === 'PRESENT').length,
        absent: dayRecords.filter((a) => a.status === 'ABSENT').length,
      });
    }

    const today = new Date().toISOString().split('T')[0];
    const todayRecords = allAttendance.filter((a) => {
      const recordDate = new Date(a.date).toISOString().split('T')[0];
      return recordDate === today;
    });

    const studentStats = students.map((s) => {
      const sAttendance = allAttendance.filter((a) => a.studentId === s.id);
      const sPresent = sAttendance.filter((a) => a.status === 'PRESENT').length;
      const sAbsent = sAttendance.filter((a) => a.status === 'ABSENT').length;
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
      .filter((s) => s.total > 0)
      .sort((a, b) => b.rate - a.rate || b.present - a.present)
      .slice(0, 5);
    const worstStudents = [...studentStats]
      .filter((s) => s.total > 0)
      .sort((a, b) => a.rate - b.rate || b.absent - a.absent)
      .slice(0, 5);

    res.json({
      success: true,
      data: {
        className: existingClass.name,
        classLevel: existingClass.level,
        totalStudents: students.length,
        overall: { total, present, absent, rate: overallRate },
        today: {
          present: todayRecords.filter((a) => a.status === 'PRESENT').length,
          absent: todayRecords.filter((a) => a.status === 'ABSENT').length,
        },
        last7Days,
        topStudents,
        worstStudents,
      },
    });
  }),
);

// ═══════════════════════════════════════════
// 7.5. الإحصائيات المتقدمة (مع فلترة زمنية + insights)
// ═══════════════════════════════════════════
app.get(
  '/api/classes/:id/advanced-stats',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.id));
    const period = (req.query.period as string) || 'month';

    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }

    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
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

    const now = new Date();
    let periodStart = new Date();
    let prevStart = new Date();
    let prevEnd = new Date();

    if (period === 'week') {
      periodStart.setDate(now.getDate() - 7);
      prevStart.setDate(now.getDate() - 14);
      prevEnd.setDate(now.getDate() - 7);
    } else if (period === 'month') {
      periodStart.setDate(now.getDate() - 30);
      prevStart.setDate(now.getDate() - 60);
      prevEnd.setDate(now.getDate() - 30);
    } else if (period === 'term') {
      periodStart.setDate(now.getDate() - 90);
      prevStart.setDate(now.getDate() - 180);
      prevEnd.setDate(now.getDate() - 90);
    } else {
      periodStart = new Date(2000, 0, 1);
      prevStart = new Date(2000, 0, 1);
      prevEnd = new Date(2000, 0, 1);
    }

    const students = await prisma.student.findMany({
      where: { classId },
      orderBy: { fullName: 'asc' },
    });
    const allAttendance = await prisma.attendance.findMany({
      where: { student: { classId } },
      orderBy: { date: 'asc' },
    });

    const periodAtt = allAttendance.filter(
      (a) => new Date(a.date) >= periodStart,
    );
    const prevAtt = allAttendance.filter((a) => {
      const d = new Date(a.date);
      return d >= prevStart && d < prevEnd;
    });

    const total = periodAtt.length;
    const present = periodAtt.filter((a) => a.status === 'PRESENT').length;
    const absent = periodAtt.filter((a) => a.status === 'ABSENT').length;
    const rate = total > 0 ? Math.round((present / total) * 100) : 0;

    const prevTotal = prevAtt.length;
    const prevPresent = prevAtt.filter((a) => a.status === 'PRESENT').length;
    const prevRate =
      prevTotal > 0 ? Math.round((prevPresent / prevTotal) * 100) : 0;
    const trend = prevRate > 0 ? rate - prevRate : 0;

    const dailyTrend: {
      date: string;
      present: number;
      absent: number;
      rate: number;
    }[] = [];

    const daysCount = period === 'week' ? 7 : period === 'term' ? 90 : 30;
    for (let i = Math.min(daysCount, 30) - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const dayRecords = periodAtt.filter((a) => {
        return new Date(a.date).toISOString().split('T')[0] === dateStr;
      });
      const dayPresent = dayRecords.filter(
        (a) => a.status === 'PRESENT',
      ).length;
      const dayAbsent = dayRecords.filter(
        (a) => a.status === 'ABSENT',
      ).length;
      const dayTotal = dayPresent + dayAbsent;
      dailyTrend.push({
        date: dateStr,
        present: dayPresent,
        absent: dayAbsent,
        rate: dayTotal > 0 ? Math.round((dayPresent / dayTotal) * 100) : 0,
      });
    }

    const weekdayPresent = [0, 0, 0, 0, 0, 0, 0];
    const weekdayTotal = [0, 0, 0, 0, 0, 0, 0];
    for (const a of periodAtt) {
      const d = new Date(a.date);
      const wd = d.getDay();
      weekdayTotal[wd]++;
      if (a.status === 'PRESENT') weekdayPresent[wd]++;
    }
    const weekdayRates = weekdayTotal.map((t, i) =>
      t > 0 ? Math.round((weekdayPresent[i] / t) * 100) : 0,
    );

    const studentStats = students.map((s) => {
      const sAtt = periodAtt.filter((a) => a.studentId === s.id);
      const sPresent = sAtt.filter((a) => a.status === 'PRESENT').length;
      const sAbsent = sAtt.filter((a) => a.status === 'ABSENT').length;
      const sTotal = sAtt.length;
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

    const activeStudents = studentStats.filter((s) => s.total >= 3);

    const topStudents = [...activeStudents]
      .sort((a, b) => b.rate - a.rate || b.present - a.present)
      .slice(0, 5);

    const worstStudents = [...activeStudents]
      .sort((a, b) => a.rate - b.rate || b.absent - a.absent)
      .slice(0, 5);

    const atRiskStudents = activeStudents.filter((s) => s.rate < 60);
    const atRiskCount = atRiskStudents.length;

    const insights: { type: string; icon: string; message: string }[] = [];

    if (total === 0) {
      insights.push({
        type: 'info',
        icon: 'info',
        message: 'لا توجد بيانات في هذه الفترة',
      });
    } else {
      if (trend >= 5) {
        insights.push({
          type: 'positive',
          icon: 'trending_up',
          message: `تحسّن ملحوظ: +${trend}% مقارنة بالفترة السابقة`,
        });
      } else if (trend <= -5) {
        insights.push({
          type: 'negative',
          icon: 'trending_down',
          message: `انخفاض: ${trend}% مقارنة بالفترة السابقة`,
        });
      } else if (prevRate > 0) {
        insights.push({
          type: 'info',
          icon: 'trending_flat',
          message: `مستقر: ${rate}% (لا تغيير ملحوظ)`,
        });
      }

      if (atRiskCount > 0) {
        insights.push({
          type: 'warning',
          icon: 'warning',
          message: `${atRiskCount} تلميذ يحتاج متابعة`,
        });
      }

      const maxRate = Math.max(...weekdayRates);
      if (maxRate > 0) {
        const dayNames = [
          'الأحد',
          'الاثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة',
          'السبت',
        ];
        const bestIdx = weekdayRates.indexOf(maxRate);
        insights.push({
          type: 'positive',
          icon: 'calendar',
          message: `أفضل يوم: ${dayNames[bestIdx]} (${maxRate}%)`,
        });
      }

      if (topStudents.length > 0 && topStudents[0].rate === 100) {
        insights.push({
          type: 'positive',
          icon: 'star',
          message: `${topStudents[0].fullName}: حضور مثالي 100% 🎯`,
        });
      }
    }

    res.json({
      success: true,
      data: {
        className: existingClass.name,
        classLevel: existingClass.level,
        period,
        totalStudents: students.length,
        overview: {
          total,
          present,
          absent,
          rate,
          trend,
          prevRate,
        },
        dailyTrend,
        weekdayRates,
        topStudents,
        worstStudents,
        atRiskCount,
        atRiskStudents: atRiskStudents.slice(0, 10).map((s) => ({
          id: s.id,
          fullName: s.fullName,
          rate: s.rate,
        })),
        insights,
      },
    });
  }),
);

// ═══════════════════════════════════════════
// 8. الدرجات
// ═══════════════════════════════════════════
const bulkGradeSchema = z.object({
  classId: z.number().int().positive(),
  assessment: z.string().min(1).max(50),
  maxScore: z.number().positive().default(20),
  coeff: z.number().int().positive().default(1),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  note: z.string().max(500).optional(),
  records: z
    .array(
      z.object({
        studentId: z.number().int().positive(),
        score: z.number().min(0).max(1000),
      }),
    )
    .min(1),
});

app.post(
  '/api/grades',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const data = bulkGradeSchema.parse(req.body);

    if (!(await ownsClass(data.classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    const gradeDate = new Date(data.date);

    await prisma.grade.deleteMany({
      where: {
        classId: data.classId,
        assessment: data.assessment,
        date: gradeDate,
        studentId: { in: data.records.map((r) => r.studentId) },
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
        }),
      ),
    );
    res.json({ success: true, data: { saved: results.length } });
  }),
);

app.get(
  '/api/classes/:id/grades',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.id));
    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }
    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
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
  }),
);

app.get(
  '/api/grades/session',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.query.classId));
    const assessment = req.query.assessment as string;
    const dateStr = req.query.date as string;

    if (isNaN(classId) || !assessment || !dateStr) {
      return res.status(400).json({
        success: false,
        error: { code: 'MISSING_PARAMS', message: 'معاملات ناقصة' },
      });
    }
    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    const gradeDate = new Date(dateStr);
    const grades = await prisma.grade.findMany({
      where: { classId, assessment, date: gradeDate },
      include: { student: { select: { id: true, fullName: true } } },
      orderBy: { student: { fullName: 'asc' } },
    });

    const records = grades.map((g) => ({
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
  }),
);

app.get(
  '/api/students/:id/grades',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const studentId = parseInt(String(req.params.id));
    if (isNaN(studentId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
      });
    }
    if (!(await ownsStudent(studentId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
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
    const average =
      totalCoeff > 0
        ? Math.round((totalWeighted / totalCoeff) * 20 * 100) / 100
        : 0;

    const byAssessment: { [key: string]: { sum: number; count: number } } = {};
    for (const g of grades) {
      if (!byAssessment[g.assessment]) {
        byAssessment[g.assessment] = { sum: 0, count: 0 };
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
        average,
        count: grades.length,
        assessmentAverages,
        records: grades.map((g) => ({
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
  }),
);

// ═══════════════════════════════════════════
// 9. سجل حضور تلميذ
// ═══════════════════════════════════════════
app.get(
  '/api/students/:id/attendance',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const studentId = parseInt(String(req.params.id));
    if (isNaN(studentId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
      });
    }
    if (!(await ownsStudent(studentId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
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
      orderBy: [{ date: 'desc' }, { period: 'asc' }],
    });
    const total = attendance.length;
    const present = attendance.filter((a) => a.status === 'PRESENT').length;
    const absent = attendance.filter((a) => a.status === 'ABSENT').length;
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
        records: attendance.map((a) => ({
          date: a.date,
          period: a.period,
          status: a.status,
        })),
      },
    });
  }),
);

// ═══════════════════════════════════════════
// 10. الملاحظات
// ═══════════════════════════════════════════
const createNoteSchema = z.object({
  classId: z.number().int().positive(),
  studentId: z.number().int().positive().nullable().optional(),
  type: z.enum(['POSITIVE', 'NEGATIVE', 'INFO', 'JOURNAL']),
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(2000),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

app.post(
  '/api/notes',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const data = createNoteSchema.parse(req.body);
    if (!(await ownsClass(data.classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }
    const noteDate = new Date(data.date);
    const note = await prisma.note.create({
      data: {
        classId: data.classId,
        studentId: data.studentId ?? null,
        type: data.type,
        title: data.title,
        content: data.content,
        date: noteDate,
      },
    });
    res.status(201).json({ success: true, data: note });
  }),
);

app.get(
  '/api/classes/:id/notes',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.id));
    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }
    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }
    const notes = await prisma.note.findMany({
      where: { classId },
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
      include: { student: { select: { id: true, fullName: true } } },
    });
    res.json({
      success: true,
      data: {
        notes: notes.map((n) => ({
          id: n.id,
          type: n.type,
          title: n.title,
          content: n.content,
          date: n.date,
          studentId: n.studentId,
          studentName: n.student?.fullName ?? null,
        })),
      },
    });
  }),
);

app.get(
  '/api/students/:id/notes',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const studentId = parseInt(String(req.params.id));
    if (isNaN(studentId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_STUDENT_ID', message: 'رقم التلميذ غير صحيح' },
      });
    }
    if (!(await ownsStudent(studentId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'STUDENT_NOT_FOUND', message: 'التلميذ غير موجود' },
      });
    }
    const notes = await prisma.note.findMany({
      where: { studentId },
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
    });
    const positive = notes.filter((n) => n.type === 'POSITIVE').length;
    const negative = notes.filter((n) => n.type === 'NEGATIVE').length;
    const info = notes.filter((n) => n.type === 'INFO').length;
    res.json({
      success: true,
      data: {
        stats: { positive, negative, info, total: notes.length },
        notes: notes.map((n) => ({
          id: n.id,
          type: n.type,
          title: n.title,
          content: n.content,
          date: n.date,
        })),
      },
    });
  }),
);

app.delete(
  '/api/notes/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const noteId = parseInt(String(req.params.id));
    if (isNaN(noteId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_NOTE_ID', message: 'رقم الملاحظة غير صحيح' },
      });
    }
    const note = await prisma.note.findFirst({
      where: { id: noteId, class: { userId: req.userId! } },
    });
    if (!note) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOTE_NOT_FOUND', message: 'الملاحظة غير موجودة' },
      });
    }
    await prisma.note.delete({ where: { id: noteId } });
    res.json({ success: true, data: { deletedId: noteId } });
  }),
);

// ═══════════════════════════════════════════
// 11. جدول الأسبوع
// ═══════════════════════════════════════════
const createScheduleSchema = z.object({
  classId: z.number().int().positive(),
  dayOfWeek: z.number().int().min(1).max(7),
  startTime: z.string().regex(/^\d{2}:\d{2}$/),
  endTime: z.string().regex(/^\d{2}:\d{2}$/),
  subject: z.string().min(1).max(100),
  room: z.string().max(50).optional().nullable(),
});

app.post(
  '/api/schedule',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const data = createScheduleSchema.parse(req.body);

    if (!(await ownsClass(data.classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    if (data.startTime >= data.endTime) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_TIME_RANGE',
          message: 'وقت البداية يجب أن يكون قبل وقت النهاية',
        },
      });
    }

    const conflict = await prisma.schedule.findFirst({
      where: {
        userId: req.userId!,
        dayOfWeek: data.dayOfWeek,
        OR: [
          {
            startTime: { lte: data.startTime },
            endTime: { gt: data.startTime },
          },
          {
            startTime: { lt: data.endTime },
            endTime: { gte: data.endTime },
          },
        ],
      },
    });

    if (conflict) {
      return res.status(409).json({
        success: false,
        error: {
          code: 'TIME_CONFLICT',
          message: 'يوجد تعارض مع حصة أخرى في هذا الوقت',
        },
      });
    }

    const schedule = await prisma.schedule.create({
      data: {
        userId: req.userId!,
        classId: data.classId,
        dayOfWeek: data.dayOfWeek,
        startTime: data.startTime,
        endTime: data.endTime,
        subject: data.subject,
        room: data.room || null,
      },
    });

    res.status(201).json({ success: true, data: schedule });
  }),
);

app.get(
  '/api/schedule',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const schedules = await prisma.schedule.findMany({
      where: { userId: req.userId! },
      orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
      include: {
        class: {
          select: { id: true, name: true, level: true },
        },
      },
    });
    res.json({ success: true, data: schedules });
  }),
);

app.get(
  '/api/schedule/day/:dayOfWeek',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const dayOfWeek = parseInt(String(req.params.dayOfWeek));
    if (isNaN(dayOfWeek) || dayOfWeek < 1 || dayOfWeek > 7) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_DAY', message: 'اليوم غير صحيح' },
      });
    }
    const schedules = await prisma.schedule.findMany({
      where: { userId: req.userId!, dayOfWeek },
      orderBy: { startTime: 'asc' },
      include: {
        class: { select: { id: true, name: true, level: true } },
      },
    });
    res.json({ success: true, data: schedules });
  }),
);

app.get(
  '/api/schedule/current',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const now = new Date();
    const jsDay = now.getDay();
    const dartDay = jsDay === 0 ? 7 : jsDay;
    const hh = now.getHours().toString().padStart(2, '0');
    const mm = now.getMinutes().toString().padStart(2, '0');
    const currentTime = `${hh}:${mm}`;

    const current = await prisma.schedule.findFirst({
      where: {
        userId: req.userId!,
        dayOfWeek: dartDay,
        startTime: { lte: currentTime },
        endTime: { gt: currentTime },
      },
      include: {
        class: { select: { id: true, name: true, level: true } },
      },
    });

    const next = await prisma.schedule.findFirst({
      where: {
        userId: req.userId!,
        dayOfWeek: dartDay,
        startTime: { gt: currentTime },
      },
      orderBy: { startTime: 'asc' },
      include: {
        class: { select: { id: true, name: true, level: true } },
      },
    });

    res.json({
      success: true,
      data: { current, next },
    });
  }),
);

app.delete(
  '/api/schedule/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const scheduleId = parseInt(String(req.params.id));
    if (isNaN(scheduleId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_ID', message: 'رقم الحصة غير صحيح' },
      });
    }
    const item = await prisma.schedule.findFirst({
      where: { id: scheduleId, userId: req.userId! },
    });
    if (!item) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'الحصة غير موجودة' },
      });
    }
    await prisma.schedule.delete({ where: { id: scheduleId } });
    res.json({ success: true, data: { deletedId: scheduleId } });
  }),
);

// ═══════════════════════════════════════════
// 12. مخطط الجلوس
// ═══════════════════════════════════════════
app.get(
  '/api/classes/:classId/seating',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.classId));
    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }
    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    let chart = await prisma.seatingChart.findUnique({
      where: { classId },
    });

    if (!chart) {
      chart = await prisma.seatingChart.create({
        data: {
          classId,
          userId: req.userId!,
          rows: 5,
          cols: 4,
          seats: {},
        },
      });
    }

    res.json({ success: true, data: chart });
  }),
);

const saveSeatingSchema = z.object({
  rows: z.number().int().min(1).max(20),
  cols: z.number().int().min(1).max(20),
  seats: z.record(z.string(), z.any()),
  delegate1: z.number().int().positive().nullable().optional(),
  delegate2: z.number().int().positive().nullable().optional(),
  delegate3: z.number().int().positive().nullable().optional(),
});

app.put(
  '/api/classes/:classId/seating',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.classId));
    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }
    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    const data = saveSeatingSchema.parse(req.body);

    const cleanSeats: { [key: string]: (number | null)[] } = {};
    for (const [key, value] of Object.entries(data.seats)) {
      if (value === null || value === undefined) continue;
      const parts = key.split('-');
      if (parts.length !== 2) continue;
      const r = parseInt(parts[0]);
      const c = parseInt(parts[1]);
      if (isNaN(r) || isNaN(c)) continue;
      if (r < 0 || r >= data.rows || c < 0 || c >= data.cols) continue;

      let ids: (number | null)[] = [];
      if (Array.isArray(value)) {
        ids = value
          .slice(0, 2)
          .map((v: any) => (typeof v === 'number' && v > 0 ? v : null));
      } else if (typeof value === 'number' && value > 0) {
        ids = [value, null];
      }

      if (ids.some((id) => id !== null)) {
        while (ids.length < 2) ids.push(null);
        cleanSeats[key] = ids;
      }
    }

    const chart = await prisma.seatingChart.upsert({
      where: { classId },
      update: {
        rows: data.rows,
        cols: data.cols,
        seats: cleanSeats,
        delegate1: data.delegate1 ?? null,
        delegate2: data.delegate2 ?? null,
        delegate3: data.delegate3 ?? null,
      },
      create: {
        classId,
        userId: req.userId!,
        rows: data.rows,
        cols: data.cols,
        seats: cleanSeats,
        delegate1: data.delegate1 ?? null,
        delegate2: data.delegate2 ?? null,
        delegate3: data.delegate3 ?? null,
      },
    });

    res.json({ success: true, data: chart });
  }),
);

app.delete(
  '/api/classes/:classId/seating',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const classId = parseInt(String(req.params.classId));
    if (isNaN(classId)) {
      return res.status(400).json({
        success: false,
        error: { code: 'INVALID_CLASS_ID', message: 'رقم القسم غير صحيح' },
      });
    }
    if (!(await ownsClass(classId, req.userId!))) {
      return res.status(404).json({
        success: false,
        error: { code: 'CLASS_NOT_FOUND', message: 'القسم غير موجود' },
      });
    }

    await prisma.seatingChart.deleteMany({ where: { classId } });
    res.json({ success: true, data: { deleted: true } });
  }),
);

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
        message: err.errors?.[0]?.message || 'بيانات غير صحيحة',
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