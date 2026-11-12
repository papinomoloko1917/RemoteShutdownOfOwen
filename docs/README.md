# Документация RemoteShutdownOfOwen V2

**DESIGN / NOT APPROVED / NOT IMPLEMENTED / SIM_ONLY.** Owen Logic 3.3.378.0, цикл SIM 100 мс.

1. [AI_HANDOFF / OWEN FIRST](../AI_HANDOFF.md), [README](../README.md), [README_CHECKPOINT редакция 12](../README_CHECKPOINT.md).
2. [Режимы ПР103](architecture/OPERATING_MODES_V2.md) и [реестр решений](architecture/SAFETY_AND_OPEN_DECISIONS.md).
3. [Архитектура](architecture/V2_ARCHITECTURE_DRAFT.md), [Modbus и свежесть](architecture/MODBUS_AND_FRESHNESS.md), [ТЗ](architecture/REQUIREMENTS_TRACEABILITY.md).
4. [План разработки](development/V2_WORK_PLAN.md), [план SIM](testing/SIM_TEST_PLAN_V2.md), [исторические результаты](testing/HISTORICAL_SIM_RESULTS.md).
5. [Официальные источники Owen Logic](reference/OWEN_LOGIC_SOURCE_AUDIT.md), [МЭ210-701](reference/ME210_701_OWEN_SOURCE_AUDIT.md), [заметки ОВЕН](reference/OWEN_REFERENCE_NOTES.md).
6. [Журнал проекта](../PROJECT_STATUS.md) — §23, §22, §21, затем исторические §§20/19.

История решений — `history/`, архивные программы — `../archive/` (без изменений). [Карта миграции](reference/FILE_MIGRATION_PLAN.md) — историческая.

**D-02 согласовано (поведение):** после ремонта оптики ПР103 **остаётся в разрешённом LOCAL**, пока персонал не совершит **новое сознательное действие**, а перед выходом не будет проверено актуальное состояние SB1. Modbus OK, новый HB и старый STOP=0 не выводят из LOCAL и не очищают LOCK. Повторное нажатие SB3 — пока инженерное предложение (D-03 OPEN); свежесть SB1, рестарты и replay (D-01/D-04), времена и реакция на SB1=1 (D-13–D-15) также OPEN.
