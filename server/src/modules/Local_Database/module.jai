select :: () {
  
}

#load "bplus_tree.jai";


/*

Documents: (Id, Uri)
Ranges: (Id, DocumentId, ResultSetId, Start, End)
ResultSets: (Id, DeclarationId, DefinitionId)
Declarations: (Id, ResultSetId, RangeId)
Definitions: (Id, ResultSetId, RangeId)

Select Doc.Uri, Ran.Start, Ran.End
From Ranges Ra
Join Documents Do
  On Do.Id = Ra.DocumentId
Join ResultSets Re
  On Re.Id = Ra.ResultSetId
Join Declarations De
  On De.Id = Re.DeclarationId
Join Ranges Ran
  On Ran.Id = De.RangeId
Join Documents Doc
  On Doc.Id = Ran.DocumentId
Where Do.Uri = @Uri and Ra.Start <= @Position and Ra.End >= @Position

Select Declaration
From ResultSets
Where Id = @ResultSet and 

*/