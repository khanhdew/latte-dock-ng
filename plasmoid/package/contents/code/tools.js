/*
    SPDX-FileCopyrightText: 2016 Smith AR <audoban@openmailbox.org>
    SPDX-FileCopyrightText: 2016-2018 Michail Vourlakos <mvourlakos@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

function wheelActivateNextPrevTask(wheelDelta, eventDelta) {
    // Use a lower threshold (15 deg = one "click" on most mice)
    wheelDelta += eventDelta;
    var increment = 0;
    while (wheelDelta >= 15) {
        wheelDelta -= 15;
        increment++;
    }
    while (wheelDelta <= -15) {
        wheelDelta += 15;
        increment--;
    }
    // Build the visual order once per wheel event.  Large high-resolution
    // wheel deltas can produce several activations and previously rebuilt the
    // same task index list for every step.
    var taskIndexList = increment !== 0 ? buildTaskIndexList() : [];
    while (increment != 0) {
        activateNextPrevTask(increment < 0, taskIndexList)
        increment += (increment < 0) ? 1 : -1;
    }

    return wheelDelta;
}

function activateTask(index, model, modifiers, task) {
    if (modifiers & Qt.ControlModifier) {
        tasksModel.requestNewInstance(index);
    } else if (task.isGroupParent) {
        task.activateNextTask();
       // if (backend.canPresentWindows()) {
        //    backend.presentWindows(model.LegacyWinIdList);
       // }
        /*} else if (groupDialog.visible) {
            groupDialog.visible = false;
        } else {
            groupDialog.visualParent = task;
            groupDialog.visible = true;
        }*/
    } else {
        if (model.IsMinimized === true) {
            tasksModel.requestToggleMinimized(index);
            tasksModel.requestActivate(index);
        } else if (model.IsActive === true) {
            tasksModel.requestToggleMinimized(index);
        } else {
            tasksModel.requestActivate(index);
        }
    }
}


function buildTaskIndexList() {
    var taskIndexList = [];
    for (var i = 0; i < taskList.children.length - 1; ++i) {
        var task = taskList.children[i];

        if (task && task.m !== undefined) {
            if (task.m.IsLauncher !== true && task.m.IsStartup !== true) {
                var modelIndex = task.modelIndex(i);
                if (task.m.IsGroupParent === true) {
                    for (var j = 0; j < tasksModel.rowCount(modelIndex); ++j) {
                        taskIndexList.push(tasksModel.makeModelIndex(i, j));
                    }
                } else {
                    taskIndexList.push(modelIndex);
                }
            }
        }
    }

    return taskIndexList;
}

function activateNextPrevTask(next, taskIndexList) {
    var activeTaskIndex = tasksModel.activeTask;

    if (taskIndexList === undefined) {
        taskIndexList = buildTaskIndexList();
    }

    if (!taskIndexList.length) {
        return;
    }

    var target = taskIndexList[0];

    for (var i = 0; i < taskIndexList.length; ++i) {
        if (taskIndexList[i] === activeTaskIndex)
        {
            if (next && i < (taskIndexList.length - 1)) {
                target = taskIndexList[i + 1];
            } else if (!next) {
                if (i) {
                    target = taskIndexList[i - 1];
                } else {
                    target = taskIndexList[taskIndexList.length - 1];
                }
            }

            break;
        }
    }

    tasksModel.requestActivate(target);
}

function insertIndexAt(above, x, y) {
    if (above && typeof above.itemIndex === "number" && above.itemIndex >= 0) {
        return above.itemIndex;
    } else {
        var distance = root.vertical ? y : x;
        //var step = root.vertical ? LayoutManager.taskWidth() : LayoutManager.taskHeight();
        var step = appletAbilities.metrics.totals.length;
        var stripe = Math.ceil(distance / step);

        /* if (stripe === LayoutManager.calculateStripes()) {
            return tasksModel.count - 1;
        } else {
            return stripe * LayoutManager.tasksPerStripe();
        }*/

        if (stripe <= 0) {
            return 0;
        }

        return stripe - 1;
    }
}
