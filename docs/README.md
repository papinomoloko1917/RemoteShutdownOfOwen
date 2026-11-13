# Документация RemoteShutdownOfOwen V2

**Состояние на 14.11.2026: V2-A UNIT-SIM PARTIALLY VERIFIED; REAL MODBUS NOT VERIFIED; HW NOT APPROVED.** Owen Logic 3.3.378.0, шаг SIM 100 мс. Нельзя превращать наблюдения с синтетическими `I2/I6` в доказательство актуальности физической SB1.

## С чего начать

1. [Правила и передача контекста](../AI_HANDOFF.md) — **OWEN FIRST**, ограничения безопасности, актуальная точка; [главный README](../README.md).
2. [Действующие файлы V2](../programs/v2/README.md) — только один рабочий проект ПР103 и текст REV2 для проверки соответствия; ПР205 V2 пока не разработан.
3. [Протокол Unit-SIM 13.11](testing/V2_SIM_RESULTS_2026-11-13.md) и [план следующих испытаний](testing/SIM_TEST_PLAN_V2.md). N-04b NOT VERIFIED, N-05b NOT TESTED, остальные статусы — строго по протоколу; [исторические SIM](testing/HISTORICAL_SIM_RESULTS.md) не переаттестованы.
4. [Пять режимов V2-A](architecture/OPERATING_MODES_V2.md), [пределы безопасности и решения](architecture/SAFETY_AND_OPEN_DECISIONS.md), [Modbus/свежесть](architecture/MODBUS_AND_FRESHNESS.md) и [трассировка требований](architecture/REQUIREMENTS_TRACEABILITY.md).
5. [Рабочий план](development/V2_WORK_PLAN.md): ПР205 SIM-передатчик только после согласования модели данных; D-01/D-04 свежесть/рестарты остаются открыты.
6. [Журнал статуса](../PROJECT_STATUS.md) §25–26, [checkpoint](../README_CHECKPOINT.md), [акт ревизии репозитория 14.11](history/REPOSITORY_CLEANUP_2026-11-14.md).

## Источники и история

- [Официальное руководство Owen Logic 3.3 — аудит](reference/OWEN_LOGIC_SOURCE_AUDIT.md), [заметки по ОВЕН](reference/OWEN_REFERENCE_NOTES.md), [МЭ210-701 — аудит](reference/ME210_701_OWEN_SOURCE_AUDIT.md); первичные файлы — в [references/owen](../references/owen/).
- [Эскиз архитектуры](architecture/V2_ARCHITECTURE_DRAFT.md), [история решений](history/V2_RESTART_DECISION_LOG.md), [карта миграции (история)](reference/FILE_MIGRATION_PLAN.md), [архивные исходники](../archive/README.md).
- ТЗ ред. 6 — **ПРОЕКТ**; указанная там структурная схема ред. 2 отсутствует в репозитории. Имеется только ред. 1; документы — [specification](../specification/README.md).

**Неприкосновенные ограничения:** никаких физических Q, K1, SB2, ЩАО, МЭ210 или реального Modbus в пределах текущего SIM. Не заявлять PL/SIL, готовность к вводу в эксплуатацию или снятие защитной блокировки на основании Modbus status/HB. Исторические T35/P04-02 — FAIL-SIM, D-01/D-04 OPEN.
