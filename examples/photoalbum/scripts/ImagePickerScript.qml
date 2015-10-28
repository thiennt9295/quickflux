import QtQuick 2.0
import QuickFlux 1.0
import QtQuick.Dialogs 1.0
import "../actions"
import "../views"
import "../stores"

Item {

    FileDialog {
        id: dialog
        title: qsTr("Pick Image")
        nameFilters: [ "Image files (*.jpg *.png)"]
    }

    Component {
        id: imagePreview

        ImagePreview {

        }
    }

    // Use AppScript to pick image from local file system, preview, and ask for confirmation.
    // (asynchronous sequence task)

    // Benefit of using AppScript
    // 1. Centralize your workflow code in one place
    // 2. Highly integrated with AppDispatcher. The order of callback execution is guaranteed in sequence order.
    // 3. Only one script can be executed at a time. Registered callbacks by previous script will be removed before started.
    // 4. exit() will remove all the registered callbacks.

    // Why not just use Promise?
    // 1. You need another library. (e.g QuickPromise)
    // 2. AppScript.exit() will remove all the registered callback completely. You can write less code.

    AppScript {
        // Run this script if "Pick Image" is clicked.
        runWhen: ActionTypes.askToPickPhoto

        script: {
            // Step 1. Open file dialog
            dialog.open();

            // Register a set of callbacks as workflow
            // Registered callbacks will be executed once only per script execution
            once(dialog.onAccepted, function() {

                // Step 2. Once user picked an image, launch preview window and ask for confirmation.
                AppActions.navigateTo(imagePreview,
                                      {source: dialog.fileUrl});

            }).then(ActionTypes.pickPhoto, function(message) {
                // The function of then() is same as once() but it won't
                // trigger the callback until once() is triggered.

                // Step 3. Add picked image to store and go back to preview page.

                PhotoStore.add(String(message.url));

                AppActions.navigateBack();

            }); // <-- You may chain then() function again.

            // Condition to terminate the workflow:
            // Force to terminate if dialog is rejected / or navigateBack is dispatched
            // That will remove all the registered callbacks

            once(dialog.onRejected,exit.bind(this,0));

            once(ActionTypes.navigateBack,exit.bind(this,0));
        }
    }

}

