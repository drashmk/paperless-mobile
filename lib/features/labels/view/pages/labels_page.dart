import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/storage_path_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/core/widgets/offline_banner.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_document_type_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_storage_path_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_tag_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/edit_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/edit_document_type_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/edit_storage_path_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/edit_tag_page.dart';
import 'package:paperless_mobile/features/home/view/widget/app_drawer.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/correspondent_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/document_type_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/storage_path_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/bloc/providers/tag_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_tab_view.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class LabelsPage extends StatefulWidget {
  const LabelsPage({Key? key}) : super(key: key);

  @override
  State<LabelsPage> createState() => _LabelsPageState();
}

class _LabelsPageState extends State<LabelsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() => setState(() => _currentIndex = _tabController.index));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, connectedState) {
          return Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(
              title: Text(
                [
                  S.of(context).labelsPageCorrespondentsTitleText,
                  S.of(context).labelsPageDocumentTypesTitleText,
                  S.of(context).labelsPageTagsTitleText,
                  S.of(context).labelsPageStoragePathTitleText
                ][_currentIndex],
              ),
              actions: [
                IconButton(
                  onPressed: [
                    _openAddCorrespondentPage,
                    _openAddDocumentTypePage,
                    _openAddTagPage,
                    _openAddStoragePathPage,
                  ][_currentIndex],
                  icon: const Icon(Icons.add),
                )
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(
                    kToolbarHeight + (!connectedState.isConnected ? 16 : 0)),
                child: Column(
                  children: [
                    if (!connectedState.isConnected) const OfflineBanner(),
                    ColoredBox(
                      color: Theme.of(context).bottomAppBarColor,
                      child: TabBar(
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        controller: _tabController,
                        tabs: [
                          Tab(
                            icon: Icon(
                              Icons.person_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          Tab(
                            icon: Icon(
                              Icons.description_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          Tab(
                            icon: Icon(
                              Icons.label_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          Tab(
                            icon: Icon(
                              Icons.folder_open,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                CorrespondentBlocProvider(
                  child: LabelTabView<Correspondent>(
                    filterBuilder: (label) => DocumentFilter(
                      correspondent: IdQueryParameter.fromId(label.id),
                      pageSize: label.documentCount ?? 0,
                    ),
                    onEdit: _openEditCorrespondentPage,
                    emptyStateActionButtonLabel: S
                        .of(context)
                        .labelsPageCorrespondentEmptyStateAddNewLabel,
                    emptyStateDescription: S
                        .of(context)
                        .labelsPageCorrespondentEmptyStateDescriptionText,
                    onAddNew: _openAddCorrespondentPage,
                  ),
                ),
                DocumentTypeBlocProvider(
                  child: LabelTabView<DocumentType>(
                    filterBuilder: (label) => DocumentFilter(
                      documentType: IdQueryParameter.fromId(label.id),
                      pageSize: label.documentCount ?? 0,
                    ),
                    onEdit: _openEditDocumentTypePage,
                    emptyStateActionButtonLabel: S
                        .of(context)
                        .labelsPageDocumentTypeEmptyStateAddNewLabel,
                    emptyStateDescription: S
                        .of(context)
                        .labelsPageDocumentTypeEmptyStateDescriptionText,
                    onAddNew: _openAddDocumentTypePage,
                  ),
                ),
                TagBlocProvider(
                  child: LabelTabView<Tag>(
                    filterBuilder: (label) => DocumentFilter(
                      tags: IdsTagsQuery.fromIds([label.id!]),
                      pageSize: label.documentCount ?? 0,
                    ),
                    onEdit: _openEditTagPage,
                    leadingBuilder: (t) => CircleAvatar(
                      backgroundColor: t.color,
                      child: t.isInboxTag ?? false
                          ? Icon(
                              Icons.inbox,
                              color: t.textColor,
                            )
                          : null,
                    ),
                    emptyStateActionButtonLabel:
                        S.of(context).labelsPageTagsEmptyStateAddNewLabel,
                    emptyStateDescription:
                        S.of(context).labelsPageTagsEmptyStateDescriptionText,
                    onAddNew: _openAddTagPage,
                  ),
                ),
                StoragePathBlocProvider(
                  child: LabelTabView<StoragePath>(
                    onEdit: _openEditStoragePathPage,
                    filterBuilder: (label) => DocumentFilter(
                      storagePath: IdQueryParameter.fromId(label.id),
                      pageSize: label.documentCount ?? 0,
                    ),
                    contentBuilder: (path) => Text(path.path ?? ""),
                    emptyStateActionButtonLabel: S
                        .of(context)
                        .labelsPageStoragePathEmptyStateAddNewLabel,
                    emptyStateDescription: S
                        .of(context)
                        .labelsPageStoragePathEmptyStateDescriptionText,
                    onAddNew: _openAddStoragePathPage,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openEditCorrespondentPage(Correspondent correspondent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) => context.read<
              LabelRepository<Correspondent, CorrespondentRepositoryState>>(),
          child: EditCorrespondentPage(correspondent: correspondent),
        ),
      ),
    );
  }

  void _openEditDocumentTypePage(DocumentType docType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) => context.read<
              LabelRepository<DocumentType, DocumentTypeRepositoryState>>(),
          child: EditDocumentTypePage(documentType: docType),
        ),
      ),
    );
  }

  void _openEditTagPage(Tag tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) =>
              context.read<LabelRepository<Tag, TagRepositoryState>>(),
          child: EditTagPage(tag: tag),
        ),
      ),
    );
  }

  void _openEditStoragePathPage(StoragePath path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) => context
              .read<LabelRepository<StoragePath, StoragePathRepositoryState>>(),
          child: EditStoragePathPage(
            storagePath: path,
          ),
        ),
      ),
    );
  }

  void _openAddCorrespondentPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) => context.read<
              LabelRepository<Correspondent, CorrespondentRepositoryState>>(),
          child: const AddCorrespondentPage(),
        ),
      ),
    );
  }

  void _openAddDocumentTypePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) => context.read<
              LabelRepository<DocumentType, DocumentTypeRepositoryState>>(),
          child: const AddDocumentTypePage(),
        ),
      ),
    );
  }

  void _openAddTagPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) =>
              context.read<LabelRepository<Tag, TagRepositoryState>>(),
          child: const AddTagPage(),
        ),
      ),
    );
  }

  void _openAddStoragePathPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepositoryProvider(
          create: (context) => context
              .read<LabelRepository<StoragePath, StoragePathRepositoryState>>(),
          child: const AddStoragePathPage(),
        ),
      ),
    );
  }
}
