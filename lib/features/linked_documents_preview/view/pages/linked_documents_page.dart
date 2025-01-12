import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/documents_list_loading_widget.dart';
import 'package:paperless_mobile/features/document_details/bloc/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/pages/document_details_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/list/document_list_item.dart';
import 'package:paperless_mobile/features/linked_documents_preview/bloc/linked_documents_cubit.dart';
import 'package:paperless_mobile/features/linked_documents_preview/bloc/state/linked_documents_state.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class LinkedDocumentsPage extends StatefulWidget {
  const LinkedDocumentsPage({super.key});

  @override
  State<LinkedDocumentsPage> createState() => _LinkedDocumentsPageState();
}

class _LinkedDocumentsPageState extends State<LinkedDocumentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).linkedDocumentsPageTitle),
      ),
      body: BlocBuilder<LinkedDocumentsCubit, LinkedDocumentsState>(
        builder: (context, state) {
          return Column(
            children: [
              Text(
                S.of(context).referencedDocumentsReadOnlyHintText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!state.isLoaded)
                Expanded(child: const DocumentsListLoadingWidget())
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: state.documents?.results.length,
                    itemBuilder: (context, index) {
                      return DocumentListItem(
                        isLabelClickable: false,
                        document: state.documents!.results.elementAt(index),
                        onTap: (doc) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => DocumentDetailsCubit(
                                  context.read<PaperlessDocumentsApi>(),
                                  state.documents!.results.elementAt(index),
                                ),
                                child: const DocumentDetailsPage(
                                  isLabelClickable: false,
                                  allowEdit: false,
                                ),
                              ),
                            ),
                          );
                        },
                        isSelected: false,
                        isAtLeastOneSelected: false,
                        isTagSelectedPredicate: (_) => false,
                        onTagSelected: (int tag) {},
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
