import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {getMessaging, MulticastMessage} from "firebase-admin/messaging";
import {logger, setGlobalOptions} from "firebase-functions/v2";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

initializeApp();
setGlobalOptions({region: "asia-southeast1", maxInstances: 10});

const db = getFirestore();

type NotificationInput = {
  notificationId: string;
  type: string;
  screen: "dashboard" | "projects" | "payments" | "teamPayouts" |
    "reserve" | "stats";
  title: string;
  body: string;
  projectId?: string;
};

async function sendToUser(uid: string, input: NotificationInput): Promise<void> {
  const userSnapshot = await db.collection("users").doc(uid).get();
  const preferences = userSnapshot.data() ?? {};
  if (input.type.startsWith("payment_") &&
      preferences.notifyPayments === false) return;
  if (input.type.startsWith("project_") &&
      preferences.notifyProjectUpdates === false) return;
  if (input.type.startsWith("team_") &&
      preferences.notifyTeamPayouts === false) return;

  const notificationRef = db
    .collection("users")
    .doc(uid)
    .collection("notifications")
    .doc(input.notificationId);

  await notificationRef.set({
    type: input.type,
    screen: input.screen,
    title: input.title,
    body: input.body,
    projectId: input.projectId ?? null,
    createdAt: FieldValue.serverTimestamp(),
    readAt: null,
  }, {merge: true});

  const devices = await db
    .collection("users")
    .doc(uid)
    .collection("devices")
    .get();
  if (devices.empty) return;

  const tokens = devices.docs
    .map((doc) => doc.get("token") as string | undefined)
    .filter((token): token is string => Boolean(token));
  if (tokens.length === 0) return;

  const data: Record<string, string> = {
    schemaVersion: "1",
    type: input.type,
    screen: input.screen,
    userId: uid,
    notificationId: input.notificationId,
  };
  if (input.projectId) data.projectId = input.projectId;

  const message: MulticastMessage = {
    tokens,
    notification: {title: input.title, body: input.body},
    data,
    android: {
      priority: "high",
      notification: {channelId: "finance_alerts", sound: "default"},
    },
    apns: {payload: {aps: {sound: "default"}}},
  };

  const result = await getMessaging().sendEachForMulticast(message);
  const deletes: Array<Promise<unknown>> = [];
  result.responses.forEach((response, index) => {
    const code = response.error?.code;
    if (code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token") {
      deletes.push(devices.docs[index].ref.delete());
    }
  });
  await Promise.all(deletes);
  logger.info("FCM sent", {
    uid,
    type: input.type,
    success: result.successCount,
    failed: result.failureCount,
  });
}

export const notifyProjectChange = onDocumentUpdated(
  "users/{uid}/projects/{projectId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const uid = event.params.uid;
    const projectId = event.params.projectId;
    const projectName = String(after.name ?? "Dự án");
    const beforePaid = Number(before.paidAmount ?? 0);
    const afterPaid = Number(after.paidAmount ?? 0);

    if (afterPaid > beforePaid) {
      await sendToUser(uid, {
        notificationId: `payment-received-${projectId}-${event.id}`,
        type: "payment_received",
        screen: "payments",
        title: "Đã ghi nhận thanh toán",
        body: `${projectName}: đã nhận thêm ${formatMoney(afterPaid - beforePaid)}`,
        projectId,
      });

      const teamPercent = Number(after.teamSharePercent ?? 0);
      if (teamPercent > 0) {
        const share = (afterPaid - beforePaid) * teamPercent / 100;
        await sendToUser(uid, {
          notificationId: `team-payout-available-${projectId}-${event.id}`,
          type: "team_payout_available",
          screen: "teamPayouts",
          title: "Có tiền cần chia cho nhóm",
          body: `${projectName}: ${formatMoney(share)} từ khoản vừa thu`,
          projectId,
        });
      }
    }

    const totalValue = Number(after.totalValue ?? 0);
    if (beforePaid < totalValue && afterPaid >= totalValue && totalValue > 0) {
      await sendToUser(uid, {
        notificationId: `payment-completed-${projectId}-${event.id}`,
        type: "payment_completed",
        screen: "payments",
        title: "Dự án đã thu đủ tiền",
        body: `${projectName}: đã hoàn tất thanh toán ${formatMoney(totalValue)}`,
        projectId,
      });
    }

    const beforeProgress = Number(before.progress ?? 0);
    const afterProgress = Number(after.progress ?? 0);
    if (beforeProgress < 1 && afterProgress >= 1) {
      await sendToUser(uid, {
        notificationId: `project-completed-${projectId}-${event.id}`,
        type: "project_completed",
        screen: "projects",
        title: "Công việc đã hoàn thành",
        body: `${projectName} đã đạt 100% tiến độ`,
        projectId,
      });
    }

    const beforeMilestones = Array.isArray(before.milestones) ?
      before.milestones : [];
    const afterMilestones = Array.isArray(after.milestones) ?
      after.milestones : [];
    const completedBefore = beforeMilestones.filter(
      (item: {isPaid?: boolean}) => item.isPaid === true,
    ).length;
    const completedAfter = afterMilestones.filter(
      (item: {isPaid?: boolean}) => item.isPaid === true,
    ).length;
    if (completedAfter > completedBefore) {
      await sendToUser(uid, {
        notificationId: `project-milestone-${projectId}-${event.id}`,
        type: "project_milestone_completed",
        screen: "projects",
        title: "Đã hoàn thành một mốc dự án",
        body: `${projectName}: ${completedAfter}/${afterMilestones.length} mốc đã xong`,
        projectId,
      });
    }

    const beforeTeamPaid = Number(before.teamPaidToDate ?? 0);
    const afterTeamPaid = Number(after.teamPaidToDate ?? 0);
    if (afterTeamPaid > beforeTeamPaid) {
      await sendToUser(uid, {
        notificationId: `team-payout-recorded-${projectId}-${event.id}`,
        type: "team_payout_recorded",
        screen: "teamPayouts",
        title: "Đã ghi nhận chia tiền",
        body: `${projectName}: vừa chia ${formatMoney(afterTeamPaid - beforeTeamPaid)}`,
        projectId,
      });
    }

    const beforeRisk = Number(before.riskScore ?? 0);
    const afterRisk = Number(after.riskScore ?? 0);
    if (beforeRisk < 55 && afterRisk >= 55) {
      await sendToUser(uid, {
        notificationId: `project-risk-${projectId}-${event.id}`,
        type: "project_risk",
        screen: "projects",
        title: "Dự án có rủi ro cao",
        body: `${projectName} vừa đạt mức rủi ro ${afterRisk}/100`,
        projectId,
      });
    }
  },
);

export const notifyOverdueProjects = onSchedule(
  {schedule: "0 8 * * *", timeZone: "Asia/Bangkok"},
  async () => {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const dateKey = today.toISOString().slice(0, 10);
    const projects = await db
      .collectionGroup("projects")
      .where("dueAt", "<", Timestamp.fromDate(today))
      .where("status", "in", ["depositReceived", "partlyPaid", "overdue"])
      .get();

    for (const project of projects.docs) {
      const userRef = project.ref.parent.parent;
      if (!userRef) continue;
      const uid = userRef.id;
      const data = project.data();
      const dueAt = data.dueAt as Timestamp | undefined;
      if (!dueAt) continue;
      const overdueDays = Math.max(
        1,
        Math.floor((today.getTime() - dueAt.toDate().getTime()) / 86400000),
      );
      const notificationId = `payment-overdue-${project.id}-${dateKey}`;
      const existing = await userRef
        .collection("notifications")
        .doc(notificationId)
        .get();
      if (existing.exists) continue;

      await project.ref.update({
        status: "overdue",
        overdueDays,
        updatedAt: FieldValue.serverTimestamp(),
      });
      await sendToUser(uid, {
        notificationId,
        type: "payment_overdue",
        screen: "payments",
        title: "Thanh toán quá hạn",
        body: `${String(data.name ?? "Dự án")} đã quá hạn ${overdueDays} ngày`,
        projectId: project.id,
      });
    }
  },
);

function formatMoney(value: number): string {
  return `${new Intl.NumberFormat("vi-VN").format(value)} ₫`;
}
