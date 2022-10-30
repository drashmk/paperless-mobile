import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_paperless_mobile/extensions/flutter_extensions.dart';
import 'package:flutter_paperless_mobile/features/documents/bloc/saved_view_cubit.dart';
import 'package:flutter_paperless_mobile/features/documents/model/document.model.dart';
import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/correspondent_query.dart';
import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/document_type_query.dart';
import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/sort_field.dart';
import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/query_type.dart';
import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/storage_path_query.dart';
import 'package:flutter_paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:flutter_paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:flutter_paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:flutter_paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:flutter_paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:flutter_paperless_mobile/features/documents/model/document_filter.dart';
import 'package:flutter_paperless_mobile/features/documents/view/widgets/search/query_type_form_field.dart';
import 'package:flutter_paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';
import 'package:flutter_paperless_mobile/features/labels/document_type/model/document_type.model.dart';
import 'package:flutter_paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:flutter_paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:flutter_paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:flutter_paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:flutter_paperless_mobile/features/scan/view/document_upload_page.dart';
import 'package:flutter_paperless_mobile/generated/l10n.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

enum DateRangeSelection { before, after }

class DocumentFilterPanel extends StatefulWidget {
  final PanelController panelController;
  final ScrollController scrollController;

  const DocumentFilterPanel({
    Key? key,
    required this.panelController,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<DocumentFilterPanel> createState() => _DocumentFilterPanelState();
}

class _DocumentFilterPanelState extends State<DocumentFilterPanel> {
  static const fkCorrespondent = DocumentModel.correspondentKey;
  static const fkDocumentType = DocumentModel.documentTypeKey;
  static const fkStoragePath = DocumentModel.storagePathKey;
  static const fkQuery = "query";
  static const fkCreatedAt = DocumentModel.createdKey;
  static const fkAddedAt = DocumentModel.addedKey;

  static const _sortFields = [
    SortField.created,
    SortField.added,
    SortField.modified,
    SortField.title,
    SortField.correspondentName,
    SortField.documentType,
    SortField.archiveSerialNumber
  ];

  final _formKey = GlobalKey<FormBuilderState>();
  bool _isQueryLoading = false;

  DateTimeRange? _dateTimeRangeOfNullable(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return null;
    }
    if (start != null && end != null) {
      return DateTimeRange(start: start, end: end);
    }
    assert(start != null || end != null);
    final singleDate = (start ?? end)!;
    return DateTimeRange(start: singleDate, end: singleDate);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentsCubit, DocumentsState>(
      listener: (context, state) {
        // Set initial values, otherwise they would not automatically update.
        _patchFromFilter(state.filter);
      },
      builder: (context, state) {
        return FormBuilder(
          key: _formKey,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildDragLine(),
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(S.of(context).documentsFilterPageResetFilterLabel),
                        onPressed: () => _resetFilter(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).documentsFilterPageTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: _onApplyFilter,
                      child: Text(S.of(context).documentsFilterPageApplyFilterLabel),
                    ),
                  ],
                ).padded(),
                Expanded(
                  child: ListView(
                    controller: widget.scrollController,
                    children: [
                      const SizedBox(
                        height: 16.0,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(S.of(context).documentsFilterPageSearchLabel),
                      ).padded(),
                      _buildQueryFormField(state),
                      _buildSortByChipsList(context, state),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(S.of(context).documentsFilterPageAdvancedLabel),
                      ).padded(),
                      _buildCreatedDateRangePickerFormField(state).padded(),
                      _buildAddedDateRangePickerFormField(state).padded(),
                      _buildCorrespondentFormField(state).padded(),
                      _buildDocumentTypeFormField(state).padded(),
                      _buildStoragePathFormField(state).padded(),
                      TagFormField(
                        name: DocumentModel.tagsKey,
                        initialValue: state.filter.tags,
                      ).padded(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetFilter(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await BlocProvider.of<DocumentsCubit>(context).updateFilter();
    BlocProvider.of<SavedViewCubit>(context).resetSelection();
    if (!widget.panelController.isPanelClosed) {
      widget.panelController.close();
    }
  }

  Widget _buildDocumentTypeFormField(DocumentsState docState) {
    return BlocBuilder<DocumentTypeCubit, Map<int, DocumentType>>(
      builder: (context, state) {
        return LabelFormField<DocumentType, DocumentTypeQuery>(
          formBuilderState: _formKey.currentState,
          name: fkDocumentType,
          state: state,
          label: S.of(context).documentDocumentTypePropertyLabel,
          initialValue: docState.filter.documentType,
          queryParameterIdBuilder: DocumentTypeQuery.fromId,
          queryParameterNotAssignedBuilder: DocumentTypeQuery.notAssigned,
          prefixIcon: const Icon(Icons.description_outlined),
        );
      },
    );
  }

  Widget _buildStoragePathFormField(DocumentsState docState) {
    return BlocBuilder<StoragePathCubit, Map<int, StoragePath>>(
      builder: (context, state) {
        return LabelFormField<StoragePath, StoragePathQuery>(
          formBuilderState: _formKey.currentState,
          name: fkStoragePath,
          state: state,
          label: S.of(context).documentStoragePathPropertyLabel,
          initialValue: docState.filter.storagePath,
          queryParameterIdBuilder: StoragePathQuery.fromId,
          queryParameterNotAssignedBuilder: StoragePathQuery.notAssigned,
          prefixIcon: const Icon(Icons.folder_outlined),
        );
      },
    );
  }

  Widget _buildQueryFormField(DocumentsState state) {
    final queryType = _formKey.currentState?.getRawValue(QueryTypeFormField.fkQueryType) ??
        QueryType.titleAndContent;
    late String label;
    switch (queryType) {
      case QueryType.title:
        label = S.of(context).documentsFilterPageQueryOptionsTitleLabel;
        break;
      case QueryType.titleAndContent:
        label = S.of(context).documentsFilterPageQueryOptionsTitleAndContentLabel;
        break;
      case QueryType.extended:
        label = S.of(context).documentsFilterPageQueryOptionsExtendedLabel;
        break;
    }

    return FormBuilderTextField(
      name: fkQuery,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_outlined),
        labelText: label,
        suffixIcon: QueryTypeFormField(
          initialValue: state.filter.queryType,
          afterSelected: (queryType) => setState(() {}),
        ),
      ),
      initialValue: state.filter.queryText,
    ).padded();
  }

  Widget _buildDateRangePickerHelper(DocumentsState state, String formFieldKey) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            label: Text(
              S.of(context).documentsFilterPageDateRangeLastSevenDaysLabel,
            ),
            onPressed: () {
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateUtils.addDaysToDate(DateTime.now(), -7),
                  end: DateTime.now(),
                ),
              );
            },
          ).padded(const EdgeInsets.only(right: 8.0)),
          ActionChip(
            label: Text(
              S.of(context).documentsFilterPageDateRangeLastMonthLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth = DateUtils.addMonthsToMonthDate(now, -1);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(firstDayOfLastMonth.year, firstDayOfLastMonth.month, now.day),
                  end: DateTime.now(),
                ),
              );
            },
          ).padded(const EdgeInsets.only(right: 8.0)),
          ActionChip(
            label: Text(
              S.of(context).documentsFilterPageDateRangeLastThreeMonthsLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth = DateUtils.addMonthsToMonthDate(now, -3);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(
                    firstDayOfLastMonth.year,
                    firstDayOfLastMonth.month,
                    now.day,
                  ),
                  end: DateTime.now(),
                ),
              );
            },
          ).padded(const EdgeInsets.only(right: 8.0)),
          ActionChip(
            label: Text(
              S.of(context).documentsFilterPageDateRangeLastYearLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth = DateUtils.addMonthsToMonthDate(now, -12);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(
                    firstDayOfLastMonth.year,
                    firstDayOfLastMonth.month,
                    now.day,
                  ),
                  end: DateTime.now(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCorrespondentFormField(DocumentsState docState) {
    return BlocBuilder<CorrespondentCubit, Map<int, Correspondent>>(
      builder: (context, state) {
        return LabelFormField<Correspondent, CorrespondentQuery>(
          formBuilderState: _formKey.currentState,
          name: fkCorrespondent,
          state: state,
          label: S.of(context).documentCorrespondentPropertyLabel,
          initialValue: docState.filter.correspondent,
          queryParameterIdBuilder: CorrespondentQuery.fromId,
          queryParameterNotAssignedBuilder: CorrespondentQuery.notAssigned,
          prefixIcon: const Icon(Icons.person_outline),
        );
      },
    );
  }

  Widget _buildCreatedDateRangePickerFormField(DocumentsState state) {
    return Column(
      children: [
        FormBuilderDateRangePicker(
          initialValue: _dateTimeRangeOfNullable(
            state.filter.createdDateAfter,
            state.filter.createdDateBefore,
          ),
          pickerBuilder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Theme.of(context).primaryColor,
                colorScheme: Theme.of(context).colorScheme,
                buttonTheme: Theme.of(context).buttonTheme,
              ),
              child: child!,
            );
          },
          format: DateFormat.yMMMd(Localizations.localeOf(context).toString()),
          fieldStartLabelText: S.of(context).documentsFilterPageDateRangeFieldStartLabel,
          fieldEndLabelText: S.of(context).documentsFilterPageDateRangeFieldEndLabel,
          firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
          lastDate: DateTime.now(),
          name: fkCreatedAt,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            labelText: S.of(context).documentCreatedPropertyLabel,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _formKey.currentState?.fields[fkCreatedAt]?.didChange(null),
            ),
          ),
        ),
        _buildDateRangePickerHelper(state, fkCreatedAt),
      ],
    );
  }

  Widget _buildAddedDateRangePickerFormField(DocumentsState state) {
    return Column(
      children: [
        FormBuilderDateRangePicker(
          initialValue: _dateTimeRangeOfNullable(
            state.filter.addedDateAfter,
            state.filter.addedDateBefore,
          ),
          pickerBuilder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Theme.of(context).primaryColor,
                colorScheme: Theme.of(context).colorScheme,
                buttonTheme: Theme.of(context).buttonTheme,
              ),
              child: child!,
            );
          },
          format: DateFormat.yMMMd(Localizations.localeOf(context).toString()),
          fieldStartLabelText: S.of(context).documentsFilterPageDateRangeFieldStartLabel,
          fieldEndLabelText: S.of(context).documentsFilterPageDateRangeFieldEndLabel,
          firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
          lastDate: DateTime.now(),
          name: fkAddedAt,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            labelText: S.of(context).documentAddedPropertyLabel,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _formKey.currentState?.fields[fkAddedAt]?.didChange(null),
            ),
          ),
        ),
        _buildDateRangePickerHelper(state, fkAddedAt),
      ],
    );
  }

  Widget _buildDragLine() {
    return Container(
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
    );
  }

  Widget _buildSortByChipsList(BuildContext context, DocumentsState state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).documentsPageOrderByLabel,
          ),
          SizedBox(
            height: kToolbarHeight,
            child: ListView.separated(
              itemCount: _sortFields.length,
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => const SizedBox(
                width: 8.0,
              ),
              itemBuilder: (context, index) =>
                  _buildActionChip(_sortFields[index], state.filter.sortField, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
      SortField sortField, SortField? currentlySelectedOrder, BuildContext context) {
    String text;
    switch (sortField) {
      case SortField.archiveSerialNumber:
        text = S.of(context).documentArchiveSerialNumberPropertyShortLabel;
        break;
      case SortField.correspondentName:
        text = S.of(context).documentCorrespondentPropertyLabel;
        break;
      case SortField.title:
        text = S.of(context).documentTitlePropertyLabel;
        break;
      case SortField.documentType:
        text = S.of(context).documentDocumentTypePropertyLabel;
        break;
      case SortField.created:
        text = S.of(context).documentCreatedPropertyLabel;
        break;
      case SortField.added:
        text = S.of(context).documentAddedPropertyLabel;
        break;
      case SortField.modified:
        text = S.of(context).documentModifiedPropertyLabel;
        break;
    }

    final docBloc = BlocProvider.of<DocumentsCubit>(context);
    return ActionChip(
      label: Text(text),
      avatar: currentlySelectedOrder == sortField
          ? const Icon(
              Icons.done,
              color: Colors.green,
            )
          : null,
      onPressed: () =>
          docBloc.updateFilter(filter: docBloc.state.filter.copyWith(sortField: sortField)),
    );
  }

  void _onApplyFilter() {
    setState(() => _isQueryLoading = true);
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      final v = _formKey.currentState!.value;
      final docCubit = BlocProvider.of<DocumentsCubit>(context);
      DocumentFilter newFilter = docCubit.state.filter.copyWith(
        createdDateBefore: (v[fkCreatedAt] as DateTimeRange?)?.end,
        createdDateAfter: (v[fkCreatedAt] as DateTimeRange?)?.start,
        correspondent: v[fkCorrespondent] as CorrespondentQuery?,
        documentType: v[fkDocumentType] as DocumentTypeQuery?,
        storagePath: v[fkStoragePath] as StoragePathQuery?,
        tags: v[DocumentModel.tagsKey] as TagsQuery?,
        page: 1,
        queryText: v[fkQuery] as String?,
        addedDateBefore: (v[fkAddedAt] as DateTimeRange?)?.end,
        addedDateAfter: (v[fkAddedAt] as DateTimeRange?)?.start,
        queryType: v[QueryTypeFormField.fkQueryType] as QueryType,
      );
      BlocProvider.of<DocumentsCubit>(context).updateFilter(filter: newFilter).then((value) {
        BlocProvider.of<SavedViewCubit>(context).resetSelection();
        FocusScope.of(context).unfocus();
        widget.panelController.close();
        setState(() => _isQueryLoading = false);
      });
    }
  }

  void _patchFromFilter(DocumentFilter f) {
    _formKey.currentState?.patchValue({
      fkCorrespondent: f.correspondent,
      fkDocumentType: f.documentType,
      fkQuery: f.queryText,
      fkStoragePath: f.storagePath,
      DocumentModel.tagsKey: f.tags,
      DocumentModel.titleKey: f.queryText,
      QueryTypeFormField.fkQueryType: f.queryType,
      fkCreatedAt: _dateTimeRangeOfNullable(
        f.createdDateAfter,
        f.createdDateBefore,
      ),
      fkAddedAt: _dateTimeRangeOfNullable(
        f.addedDateAfter,
        f.addedDateBefore,
      ),
    });
  }
}
