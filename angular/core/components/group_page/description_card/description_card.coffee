angular.module('loomioApp').directive 'descriptionCard', ->
  scope: {group: '='}
  restrict: 'E'
  templateUrl: 'generated/components/group_page/description_card/description_card.html'
  replace: true
  controller: ($scope, FormService) ->
    $scope.editorEnabled = false;

    $scope.enableEditor = ->
      $scope.editorEnabled = true
      $scope.editableDescription = $scope.group.description

    $scope.disableEditor = ->
     $scope.editorEnabled = false

    $scope.save = FormService.submit $scope, $scope.group,
      draftFields: ['description'],
      prepareFn: -> $scope.group.description = $scope.editableDescription
      flashSuccess: 'description_card.messages.description_updated'
      successCallback: -> $scope.disableEditor()
