using TMPro;
using UnityEngine;
using VRC.SDKBase;

public class DisplayCurrentOwner : Observer
{
    [SerializeField]
    private Store store;

    private TextMeshProUGUI displayText
    {
        get
        {
            return gameObject.GetComponent<TextMeshProUGUI>();
        }
    }

    public override void OnNotify()
    {
        displayText.text = Networking.GetOwner(store.gameObject).displayName;
    }
}
