# Документация RemoteShutdownOfOwen V2

**V2-A APPROVED FOR SIM DESIGN / NOT IMPLEMENTED / NOT TESTED / HW NOT APPROVED.** Owen Logic 3.3.378.0, цикл SIM 100 мс.

1. [AI_HANDOFF / OWEN FIRST](../AI_HANDOFF.md), [README](../README.md), [README_CHECKPOINT редакция 13](../README_CHECKPOINT.md).
2. [Режимы ПР103](architecture/OPERATING_MODES_V2.md) и [реестр решений](architecture/SAFETY_AND_OPEN_DECISIONS.md).
3. [Архитектура](architecture/V2_ARCHITECTURE_DRAFT.md), [Modbus и свежесть](architecture/MODBUS_AND_FRESHNESS.md), [ТЗ](architecture/REQUIREMENTS_TRACEABILITY.md).
4. [План разработки](development/V2_WORK_PLAN.md), [план SIM](testing/SIM_TEST_PLAN_V2.md), [исторические результаты](testing/HISTORICAL_SIM_RESULTS.md).
5. [Официальные источники Owen Logic](reference/OWEN_LOGIC_SOURCE_AUDIT.md), [МЭ210-701](reference/ME210_701_OWEN_SOURCE_AUDIT.md), [заметки ОВЕН](reference/OWEN_REFERENCE_NOTES.md).
6. [Журнал проекта](../PROJECT_STATUS.md) — §24 актуальный, §23 и более ранние — история.

История решений — `history/`, архивные программы — `../archive/` (без изменений). [Карта миграции](reference/FILE_MIGRATION_PLAN.md) — историческая.

**УТВЕРЖДЕНО 12.11.2026 — V2-A / SIM_ONLY:** ПР205 передаёт SB1; ПР103 использует пять состояний `INIT_UNTRUSTED`, `REMOTE`, `LOSS_LOCK`, `LOCAL`, `RECOVERY_WAIT` и раздельные `STOP_REQUEST`/`RELEASE_PERMISSION`. Существующая SB3 используется для **двух отдельных новых нажатий**: вход в LOCAL из LOSS_LOCK и запрос возврата из LOCAL после ремонта оптики. Между нажатиями обязательно отпускание; удержание при запуске не считается новым действием. Восстановление Modbus/HB/старого STOP=0 само не выводит из LOCAL. Подтверждённая **текущая** SB1=1 имеет приоритет STOP даже в LOCAL; STOP не снимается последующей SB1=0 без разрешённого перехода. При неудаче проверки или повторном обрыве во время RECOVERY_WAIT → LOSS_LOCK, STOP=1; возврат в REMOTE лишь после санкции персонала и подтверждения SB1=0.

**Граница утверждения:** `APPROVED FOR SIM DESIGN / NOT IMPLEMENTED / NOT TESTED / HW NOT APPROVED`. **D-01/D-04 OPEN:** действительная свежесть SB1 при незамеченных рестартах, replay/wrap/старых данных не доказана; HB и Modbus status недостаточны. Для SIM автомата допускаются *искусственно заданные* валидные входы, но не утверждение реального обмена. Времена D-13/D-14, МЭ210 D-09, аппаратные D-05–D-12 OPEN. ТЗ ред. 6 — ПРОЕКТ. Физические Q/K1/SB2/ЩАО/МЭ210 не трогать; новых `.owle` и PASS-SIM V2 нет; T35/P04-02 остаются FAIL-SIM.
